import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;
import 'package:debounce_throttle/debounce_throttle.dart';

class LocationData {
  final double latitude;
  final double longitude;
  LocationData({required this.latitude, required this.longitude});
}

class MainPage extends StatefulWidget {
  final String username;
  final Map<String, dynamic> userData;
  const MainPage({required this.username, required this.userData, super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> signalements = [];
  List<Map<String, dynamic>> filteredSignalements = [];
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> arrondissements = [];
  List<double> _signalementScales = [];
  double _buttonScale = 1.0;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isDialogOpen = false;
  Timer? _autoRefreshTimer;
  final TextEditingController _searchController = TextEditingController();
  final _searchDebouncer = Debouncer<String>(
    const Duration(milliseconds: 300),
    initialValue: '',
  );

  static final Map<int, List<Map<String, dynamic>>> _arrSignalementsCache = {};

  int get unreadNotificationCount =>
      notifications.where((n) => !(n['isRead'] ?? false)).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      _searchDebouncer.value = _searchController.text;
    });
    _searchDebouncer.values.listen((search) {
      _filterSignalements(search);
    });
    _fetchData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      final signalementData =
          await apiService.getSignalementsByUser(widget.username);
      final notificationData =
          await apiService.getUserNotifications(widget.username);
      final arrondissementData =
          await apiService.getArrondissements(widget.username);

      if (!mounted) return;

      final validSignalements = signalementData.where((s) {
        try {
          return s['id'] != null &&
              s['createdAt'] != null &&
              DateTime.tryParse(s['createdAt']) != null &&
              s['title'] != null &&
              s['latitude'] != null &&
              s['longitude'] != null &&
              s['arrondissementId'] != null;
        } catch (e) {
          print(
              'Invalid signalement filtered out in _fetchData: $s, error: $e');
          return false;
        }
      }).toList();

      setState(() {
        signalements = List<Map<String, dynamic>>.from(validSignalements)
          ..sort((a, b) => DateTime.parse(b['createdAt'])
              .compareTo(DateTime.parse(a['createdAt'])));
        filteredSignalements = List<Map<String, dynamic>>.from(signalements);
        notifications = List<Map<String, dynamic>>.from(notificationData)
          ..sort((a, b) => DateTime.parse(b['createdAt'])
              .compareTo(DateTime.parse(a['createdAt'])));
        arrondissements = arrondissementData;
        _signalementScales = List.filled(signalements.length, 1.0);
        _isLoading = false;
      });

      await Future.wait(signalements.asMap().entries.map((entry) async {
        final index = entry.key;
        final signalement = entry.value;
        signalement['similarCount'] =
            await _calculateSimilarSignalements(signalement);
        if (mounted) {
          setState(() {
            _signalementScales[index] = 1.0;
          });
        }
      }));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Erreur de chargement des données: $e', false);
      }
    }
  }

  void _filterSignalements(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSignalements = List<Map<String, dynamic>>.from(signalements);
      });
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredSignalements = signalements.where((s) {
        final title = (s['title'] ?? '').toLowerCase();
        final description = (s['description'] ?? '').toLowerCase();
        final arrName = (s['arrondissementName'] ?? 'Inconnu').toLowerCase();
        return title.contains(lowerQuery) ||
            description.contains(lowerQuery) ||
            arrName.contains(lowerQuery);
      }).toList();
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (_isDialogOpen) {
        print('Auto-refresh paused due to open dialog');
        return;
      }
      try {
        final newSignalements =
            await ApiService().getSignalementsByUser(widget.username);
        final validNewSignalements = newSignalements.where((s) {
          try {
            final isValid = s['id'] != null &&
                s['createdAt'] != null &&
                DateTime.tryParse(s['createdAt']) != null &&
                s['title'] != null &&
                s['latitude'] != null &&
                s['longitude'] != null &&
                s['arrondissementId'] != null;
            if (!isValid) {
              print(
                  'Invalid signalement filtered out in _startAutoRefresh: $s');
            }
            return isValid;
          } catch (e) {
            print('Error filtering signalement: $s, error: $e');
            return false;
          }
        }).toList();

        final newSignalementsSorted =
            List<Map<String, dynamic>>.from(validNewSignalements)
              ..sort((a, b) => DateTime.parse(b['createdAt'])
                  .compareTo(DateTime.parse(a['createdAt'])));
        final newIds = newSignalementsSorted.map((s) => s['id']).toSet();
        final existingIds = signalements.map((s) => s['id']).toSet();

        final toAdd = newSignalementsSorted
            .where((s) => !existingIds.contains(s['id']))
            .toList();
        final toRemove =
            signalements.where((s) => !newIds.contains(s['id'])).toList();

        if (toAdd.isNotEmpty || toRemove.isNotEmpty) {
          print(
              'Updating signalements: ${toAdd.length} added, ${toRemove.length} removed');
          setState(() {
            signalements = newSignalementsSorted;
            filteredSignalements =
                List<Map<String, dynamic>>.from(signalements);
            _signalementScales = List.filled(signalements.length, 1.0);
          });
          await Future.wait(signalements.asMap().entries.map((entry) async {
            final signalement = entry.value;
            signalement['similarCount'] =
                await _calculateSimilarSignalements(signalement);
          }));
          if (mounted) setState(() {});
        }
      } catch (e) {
        print('Erreur lors de la mise à jour automatique: $e');
      }
    });
  }

  Future<int> _calculateSimilarSignalements(
      Map<String, dynamic> signalement) async {
    final lat = signalement['latitude'] as double?;
    final lon = signalement['longitude'] as double?;
    final arrId = signalement['arrondissementId'] as int?;
    final title = signalement['title'] as String?;
    if (lat == null || lon == null || arrId == null || title == null) {
      print(
          'Invalid signalement data in _calculateSimilarSignalements: $signalement');
      return 0;
    }

    try {
      final arrSignalements = _arrSignalementsCache[arrId] ??
          await ApiService()
              .getSignalementsByArrondissement(arrId, widget.username);
      _arrSignalementsCache[arrId] = arrSignalements;

      final filteredSignalements = arrSignalements.where((s) {
        final sTitle = s['title'] as String?;
        final sLat = s['latitude'] as double?;
        final sLon = s['longitude'] as double?;
        if (sTitle != title || sLat == null || sLon == null) return false;
        final distance = Geolocator.distanceBetween(lat, lon, sLat, sLon);
        return distance <= 100;
      }).toList();

      print(
          'Similar signalements for ${signalement['id']}: ${filteredSignalements.length}');
      return filteredSignalements.length;
    } catch (e) {
      print('Erreur lors du calcul des signalements similaires: $e');
      return 0;
    }
  }

  bool _isPointInPolygon(double lat, double lon, String geoJson) {
    try {
      final geo = jsonDecode(geoJson);
      if (geo['type'] != 'Polygon') return false;
      final coordinates = (geo['coordinates'][0] as List)
          .map((point) => [point[0] as double, point[1] as double])
          .toList()
          .cast<List<double>>();
      final points =
          coordinates.map((p) => pip.Point(x: p[0], y: p[1])).toList();
      return pip.Poly.isPointInPolygon(pip.Point(x: lon, y: lat), points);
    } catch (e) {
      print('Erreur lors de la vérification du point dans le polygone: $e');
      return false;
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showNotificationsDialog() {
    setState(() {
      _isDialogOpen = true;
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Notifications',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _isDialogOpen = false;
                              });
                            }),
                      ],
                    ),
                    Expanded(
                      child: notifications.isEmpty
                          ? const Center(
                              child: Text('Aucune notification',
                                  style: TextStyle(fontSize: 18)))
                          : ListView.separated(
                              itemCount: notifications.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return ListTile(
                                  onTap: () async {
                                    if (!(notification['isRead'] ?? false)) {
                                      try {
                                        await ApiService()
                                            .markNotificationAsRead(
                                                notification['id'].toString(),
                                                widget.username);
                                        setState(() {
                                          notifications[index]['isRead'] = true;
                                        });
                                        setDialogState(() {});
                                        _showSnackBar(
                                            'Notification marquée comme lue',
                                            true);
                                      } catch (e) {
                                        _showSnackBar('Erreur: $e', false);
                                      }
                                    }
                                  },
                                  title: Text(
                                    notification['message'] ?? 'Aucun message',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            notification['isRead'] ?? false
                                                ? FontWeight.normal
                                                : FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    notification['createdAt']?.split('T')[0] ??
                                        'Date inconnue',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmation'),
                                          content: const Text(
                                              'Voulez-vous vraiment supprimer cette notification ?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Annuler')),
                                            TextButton(
                                              onPressed: () async {
                                                try {
                                                  await ApiService()
                                                      .deleteNotification(
                                                          notification['id']
                                                              .toString(),
                                                          widget.username);
                                                  setState(() {
                                                    notifications
                                                        .removeAt(index);
                                                  });
                                                  setDialogState(() {});
                                                  Navigator.pop(context);
                                                  _showSnackBar(
                                                      'Notification supprimée avec succès',
                                                      true);
                                                } catch (e) {
                                                  _showSnackBar(
                                                      'Erreur: $e', false);
                                                }
                                              },
                                              child: const Text('Supprimer',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSignalementDetails(Map<String, dynamic> signalement) {
    setState(() {
      _isDialogOpen = true;
    });
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _isDialogOpen = false;
                          });
                        }),
                  ]),
                  if (signalement['imageBase64'] != null &&
                      signalement['imageBase64'].isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        ApiService().decodeImage(signalement['imageBase64']),
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            SvgPicture.asset(
                                'assets/images/default_signalement.svg',
                                height: 150,
                                width: 150,
                                fit: BoxFit.contain),
                      ),
                    )
                  else
                    SvgPicture.asset('assets/images/default_signalement.svg',
                        height: 150, width: 150, fit: BoxFit.contain),
                  const SizedBox(height: 10),
                  Text(signalement['title'] ?? 'Aucun titre',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 5),
                  Text(signalement['arrondissementName'] ?? 'Inconnu',
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(signalement['description'] ?? 'Aucune description',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 5),
                  Text(
                      'Position: (${signalement['latitude'] ?? 'N/A'}, ${signalement['longitude'] ?? 'N/A'})',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        signalement['receptionStatus'] ?? 'Inconnu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: signalement['receptionStatus'] == 'Reçu'
                              ? Colors.green
                              : signalement['receptionStatus'] == 'En cours'
                                  ? Colors.blue
                                  : Colors.red,
                        ),
                      ),
                      Text(
                        signalement['traitementStatus'] ?? 'Inconnu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: signalement['traitementStatus'] == 'En attente'
                              ? Colors.brown
                              : signalement['traitementStatus'] == 'Traité'
                                  ? Colors.yellow[700]
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                      'Signalements similaires: ${signalement['similarCount'] ?? 0}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileDialog() {
    setState(() {
      _isDialogOpen = true;
    });
    final username = widget.username;
    final emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final newEmailController = TextEditingController();
    final confirmEmailController = TextEditingController();
    final initials =
        username.isNotEmpty ? username.substring(0, 2).toUpperCase() : '??';

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _isDialogOpen = false;
                          });
                        }),
                  ]),
                  CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green,
                      child: Text(initials,
                          style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  Text('Utilisateur: $username',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Email: ${emailController.text}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  const Text('Modifier le mot de passe',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                      controller: oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Ancien mot de passe',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Modifier',
                    onPressed: () async {
                      if (newPasswordController.text ==
                          confirmPasswordController.text) {
                        try {
                          await ApiService().updateProfile(
                            userId: widget.userData['id'],
                            username: username,
                            oldPassword: oldPasswordController.text,
                            newPassword: newPasswordController.text,
                          );
                          Navigator.pop(context);
                          setState(() {
                            _isDialogOpen = false;
                          });
                          _showSnackBar(
                              'Mot de passe modifié avec succès !', true);
                        } catch (e) {
                          _showSnackBar('Erreur: $e', false);
                        }
                      } else {
                        _showSnackBar(
                            'Les mots de passe ne correspondent pas.', false);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Modifier l\'email',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                      controller: newEmailController,
                      decoration: const InputDecoration(
                          labelText: 'Nouvel email',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                      controller: confirmEmailController,
                      decoration: const InputDecoration(
                          labelText: 'Confirmer l\'email',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Modifier',
                    onPressed: () async {
                      if (newEmailController.text ==
                          confirmEmailController.text) {
                        try {
                          await ApiService().updateProfile(
                            userId: widget.userData['id'],
                            username: username,
                            email: newEmailController.text,
                          );
                          setState(() {
                            widget.userData['email'] = newEmailController.text;
                            emailController.text = newEmailController.text;
                            _isDialogOpen = false;
                          });
                          Navigator.pop(context);
                          _showSnackBar('Email modifié avec succès !', true);
                        } catch (e) {
                          _showSnackBar('Erreur: $e', false);
                        }
                      } else {
                        _showSnackBar(
                            'Les emails ne correspondent pas.', false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSignalementDialog() {
    setState(() {
      _isDialogOpen = true;
      _autoRefreshTimer?.cancel();
    });

    final PageController pageController = PageController();
    int? selectedArrondissementId;
    String? latitude;
    String? longitude;
    String? selectedSignalementType;
    String? description;
    Uint8List? imageBytes;
    int _currentPage = 0;
    double _cameraIconScale = 1.0;
    bool isLocationLoading = false;

    final List<String> signalementTypes = [
      'Route endommagée',
      'Pont instable',
      'Déchets accumulés',
      'Trottoir fissuré',
      'Égout bouché',
      'Panneau endommagé',
      'Eau stagnante',
      'Route inondée',
      'Poubelle débordante',
      'Éclairage défectueux'
    ];

    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage(Function setDialogState, ImageSource source) async {
      try {
        final XFile? photo = await _picker.pickImage(source: source);
        if (photo != null) {
          final bytes = await photo.readAsBytes();
          setDialogState(() {
            imageBytes = bytes;
          });
        }
      } catch (e) {
        _showSnackBar('Erreur lors du choix de l\'image: $e', false);
      }
    }

    void _removeImage(Function setDialogState) {
      setDialogState(() {
        imageBytes = null;
      });
      _showSnackBar('Image supprimée', true);
    }

    Future<LocationData> _getLocation() async {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Permission de localisation refusée.', false);
          return LocationData(latitude: 0.0, longitude: 0.0);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            'Permission de localisation refusée définitivement.', false);
        return LocationData(latitude: 0.0, longitude: 0.0);
      }
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        return LocationData(
            latitude: position.latitude, longitude: position.longitude);
      } catch (e) {
        _showSnackBar(
            'Erreur lors de la récupération de la localisation: $e', false);
        return LocationData(latitude: 0.0, longitude: 0.0);
      }
    }

    void _submitSignalement() async {
      try {
        final location = await _getLocation();
        if (location.latitude == 0.0 && location.longitude == 0.0) {
          setState(() {
            _isDialogOpen = false;
            _startAutoRefresh();
          });
          return;
        }
        final selectedArrondissement = arrondissements
            .firstWhere((a) => a['id'] == selectedArrondissementId);
        final receptionStatus = _isPointInPolygon(location.latitude,
                location.longitude, selectedArrondissement['geo'])
            ? 'Reçu'
            : 'Rejeté';

        // Log signalement structure
        final signalementData = {
          'title': selectedSignalementType ?? 'Inconnu',
          'arrondissementId': selectedArrondissementId ?? 0,
          'description': description ?? '',
          'latitude': location.latitude,
          'longitude': location.longitude,
          'username': widget.username,
          'receptionStatus': receptionStatus,
        };
        print('Signalement data before sending: $signalementData');
        print('Image bytes length: ${imageBytes?.length ?? 0}');

        final newSignalement = await ApiService().createSignalement(
          title: selectedSignalementType ?? '',
          arrondissementId: selectedArrondissementId ?? 0,
          description: description ?? '',
          imageBytes: imageBytes,
          latitude: location.latitude,
          longitude: location.longitude,
          username: widget.username,
          receptionStatus: receptionStatus,
        );

        // Create notification
        Map<String, dynamic>? notificationResponse;
        try {
          notificationResponse = await ApiService().createNotification(
            userId: widget.userData['id'],
            signalementId: newSignalement['id'],
            message:
                'Signalement "${selectedSignalementType}" créé avec le statut: $receptionStatus',
            username: widget.username,
          );
        } catch (e) {
          print('Erreur lors de la création de la notification: $e');
          notificationResponse = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': widget.userData['id'],
            'signalementId': newSignalement['id'],
            'message':
                'Signalement "${selectedSignalementType}" créé avec le statut: $receptionStatus',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }

        setState(() {
          notifications.insert(0, {
            'id': notificationResponse!['id'].toString(),
            'userId': notificationResponse['userId'],
            'signalementId': notificationResponse['signalementId'],
            'message': notificationResponse['message'],
            'isRead': notificationResponse['isRead'] ?? false,
            'createdAt': notificationResponse['createdAt'] ??
                DateTime.now().toIso8601String(),
          });
        });

        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            Future.delayed(const Duration(seconds: 4), () {
              if (Navigator.of(context).canPop()) {
                print('Auto-closing confirmation dialog after 4 seconds');
                Navigator.pop(context);
                setState(() {
                  _isDialogOpen = false;
                });
                _fetchData();
                _startAutoRefresh();
              }
            });
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              backgroundColor: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/confirmation.svg',
                        height: 150,
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Merci pour votre signalement',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        _showSnackBar('Signalement créé avec succès !', true);
      } catch (e) {
        print('Erreur lors de l\'envoi du signalement: $e');
        _showSnackBar('Erreur lors de la création du signalement: $e', false);
        setState(() {
          _isDialogOpen = false;
        });
        Navigator.pop(context);
        _startAutoRefresh();
      }
    }

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void _nextPage() {
            if (_currentPage == 0 && selectedArrondissementId == null) {
              _showSnackBar('Veuillez sélectionner un arrondissement.', false);
              return;
            }
            if (_currentPage == 1 && selectedSignalementType == null) {
              _showSnackBar(
                  'Veuillez sélectionner un type de signalement.', false);
              return;
            }
            if (_currentPage == 2 &&
                (description == null || description!.isEmpty)) {
              _showSnackBar('Veuillez fournir une description.', false);
              return;
            }
            if (_currentPage < 4) {
              pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
              setDialogState(() {
                _currentPage++;
              });
            }
          }

          void _previousPage() {
            if (_currentPage > 0) {
              pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
              setDialogState(() {
                _currentPage--;
              });
            }
          }

          String _truncateImageName() {
            return imageBytes != null ? 'Image sélectionnée' : 'Aucune image';
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _isDialogOpen = false;
                            });
                            _startAutoRefresh();
                          }),
                    ]),
                    Expanded(
                      child: PageView(
                        controller: pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setDialogState(() {
                            _currentPage = index;
                            if (_currentPage == 4 && latitude == null) {
                              isLocationLoading = true;
                              _getLocation().then((location) {
                                setDialogState(() {
                                  latitude = location.latitude.toString();
                                  longitude = location.longitude.toString();
                                  isLocationLoading = false;
                                });
                              }).catchError((e) {
                                setDialogState(() {
                                  isLocationLoading = false;
                                });
                              });
                            }
                          });
                        },
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                  'assets/images/arrondissement.svg',
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.contain),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                    5,
                                    (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: index == _currentPage
                                                ? Colors.green
                                                : Colors.grey))),
                              ),
                              const SizedBox(height: 20),
                              const Text('Choisir un arrondissement',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              DropdownButton<int>(
                                value: selectedArrondissementId,
                                hint: const Text(
                                    'Sélectionner un arrondissement'),
                                items: arrondissements
                                    .map((arr) => DropdownMenuItem<int>(
                                        value: arr['id'],
                                        child: Text(arr['name'])))
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedArrondissementId = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                  'assets/images/signalement_type.svg',
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.contain),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                    5,
                                    (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: index == _currentPage
                                                ? Colors.green
                                                : Colors.grey))),
                              ),
                              const SizedBox(height: 20),
                              const Text('Choisir le type de signalement',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              DropdownButton<String>(
                                value: selectedSignalementType,
                                hint: const Text(
                                    'Sélectionner un type de signalement'),
                                items: signalementTypes
                                    .map((type) => DropdownMenuItem<String>(
                                        value: type, child: Text(type)))
                                    .toList(),
                                onChanged: (value) => setDialogState(() {
                                  selectedSignalementType = value;
                                }),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/images/description.svg',
                                  height: 200, width: 200, fit: BoxFit.contain),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                    5,
                                    (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: index == _currentPage
                                                ? Colors.green
                                                : Colors.grey))),
                              ),
                              const SizedBox(height: 20),
                              const Text('Fournir une description',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              TextField(
                                onChanged: (value) => setDialogState(() {
                                  description = value;
                                }),
                                decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder()),
                                maxLines: 3,
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'assets/images/upload_image.svg',
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.contain),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                      5,
                                      (index) => Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: index == _currentPage
                                                  ? Colors.green
                                                  : Colors.grey))),
                                ),
                                const SizedBox(height: 20),
                                const Text('Ajouter une photo (optionnel)',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTapDown: (_) => setDialogState(() {
                                        _cameraIconScale = 0.9;
                                      }),
                                      onTapUp: (_) => setDialogState(() {
                                        _cameraIconScale = 1.0;
                                        _pickImage(
                                            setDialogState, ImageSource.camera);
                                      }),
                                      onTapCancel: () => setDialogState(() {
                                        _cameraIconScale = 1.0;
                                      }),
                                      child: AnimatedScale(
                                        scale: _cameraIconScale,
                                        duration:
                                            const Duration(milliseconds: 100),
                                        child: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: SvgPicture.asset(
                                                'assets/images/camera_icon.svg',
                                                height: 40,
                                                width: 40,
                                                fit: BoxFit.contain)),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    GestureDetector(
                                      onTapDown: (_) => setDialogState(() {
                                        _cameraIconScale = 0.9;
                                      }),
                                      onTapUp: (_) => setDialogState(() {
                                        _cameraIconScale = 1.0;
                                        _pickImage(setDialogState,
                                            ImageSource.gallery);
                                      }),
                                      onTapCancel: () => setDialogState(() {
                                        _cameraIconScale = 1.0;
                                      }),
                                      child: AnimatedScale(
                                        scale: _cameraIconScale,
                                        duration:
                                            const Duration(milliseconds: 100),
                                        child: const SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Icon(Icons.photo_library,
                                                size: 40, color: Colors.green)),
                                      ),
                                    ),
                                  ],
                                ),
                                if (imageBytes != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.image, size: 20),
                                            const SizedBox(width: 8),
                                            Text(_truncateImageName(),
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                          ],
                                        ),
                                        IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 20),
                                            onPressed: () =>
                                                _removeImage(setDialogState)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      imageBytes!,
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 150,
                                        width: 150,
                                        color: Colors.grey[300],
                                        child: const Center(
                                            child: Text(
                                                'Erreur de chargement de l\'image',
                                                style: TextStyle(
                                                    color: Colors.red),
                                                textAlign: TextAlign.center)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/images/location.svg',
                                  height: 200, width: 200, fit: BoxFit.contain),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                    5,
                                    (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: index == _currentPage
                                                ? Colors.green
                                                : Colors.grey))),
                              ),
                              const SizedBox(height: 20),
                              const Text('Informations de localisation',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              isLocationLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      'Latitude: ${latitude ?? 'Non disponible'}\nLongitude: ${longitude ?? 'Non disponible'}',
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          CustomButton(
                              text: 'Précédent', onPressed: _previousPage),
                        CustomButton(
                          text: _currentPage == 3 && imageBytes == null
                              ? 'Passer'
                              : _currentPage == 4
                                  ? 'Terminer'
                                  : 'Suivant',
                          onPressed: (_currentPage == 0 &&
                                      selectedArrondissementId == null) ||
                                  (_currentPage == 1 &&
                                      selectedSignalementType == null) ||
                                  (_currentPage == 2 &&
                                      (description == null ||
                                          description!.isEmpty)) ||
                                  (_currentPage == 4 && isLocationLoading)
                              ? null
                              : _currentPage == 4
                                  ? _submitSignalement
                                  : _nextPage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignalementList(List<Map<String, dynamic>> signalementsToShow) {
    if (signalementsToShow.isEmpty) {
      return const Center(
          child:
              Text('Aucun signalement trouvé', style: TextStyle(fontSize: 18)));
    }
    return ListView.builder(
      itemCount: signalementsToShow.length,
      itemBuilder: (context, index) {
        final signalement = signalementsToShow[index];
        final globalIndex = signalements.indexOf(signalement);
        if (globalIndex < 0 || globalIndex >= _signalementScales.length) {
          print(
              'Invalid globalIndex: $globalIndex for signalement: ${signalement['id']}');
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTapDown: (_) => setState(() {
            _signalementScales[globalIndex] = 0.95;
          }),
          onTapUp: (_) => setState(() {
            _signalementScales[globalIndex] = 1.0;
            _showSignalementDetails(signalement);
          }),
          onTapCancel: () => setState(() {
            _signalementScales[globalIndex] = 1.0;
          }),
          child: AnimatedScale(
            scale: _signalementScales[globalIndex],
            duration: const Duration(milliseconds: 100),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: ListTile(
                leading: signalement['imageBase64'] != null &&
                        signalement['imageBase64'].isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          ApiService().decodeImage(signalement['imageBase64']),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              SvgPicture.asset(
                                  'assets/images/default_signalement.svg',
                                  width: 50,
                                  height: 50),
                        ),
                      )
                    : SvgPicture.asset('assets/images/default_signalement.svg',
                        width: 50, height: 50),
                title: Text(
                  signalement['title'] ?? 'Aucun titre',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(signalement['arrondissementName'] ?? 'Inconnu',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            signalement['createdAt']?.split('T')[0] ??
                                'Date inconnue',
                            style: const TextStyle(fontSize: 12)),
                        Row(
                          children: [
                            Text(
                              signalement['receptionStatus'] ?? 'Inconnu',
                              style: TextStyle(
                                fontSize: 12,
                                color: signalement['receptionStatus'] == 'Reçu'
                                    ? Colors.green
                                    : signalement['receptionStatus'] ==
                                            'En cours'
                                        ? Colors.blue
                                        : Colors.red,
                              ),
                            ),
                            Text(
                              ' | ${signalement['traitementStatus'] ?? 'Inconnu'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: signalement['traitementStatus'] ==
                                        'En attente'
                                    ? Colors.brown
                                    : signalement['traitementStatus'] ==
                                            'Traité'
                                        ? Colors.yellow[700]
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text('Similaires: ${signalement['similarCount'] ?? 0}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green, Colors.red, Colors.yellow],
                  transform:
                      GradientRotation(45 * 3.14159265358979323846 / 180),
                ),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: SvgPicture.asset(
                                'assets/images/citizen_act_logo.svg',
                                height: 50,
                                width: 50,
                                fit: BoxFit.contain)),
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.notifications,
                                        color: Colors.white),
                                    onPressed: _showNotificationsDialog),
                                if (unreadNotificationCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      constraints: const BoxConstraints(
                                          minWidth: 16, minHeight: 16),
                                      child: Text('$unreadNotificationCount',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                          textAlign: TextAlign.center),
                                    ),
                                  ),
                              ],
                            ),
                            IconButton(
                                icon: const Icon(Icons.person,
                                    color: Colors.white),
                                onPressed: _showProfileDialog),
                            IconButton(
                              icon: Icon(
                                  _isSearching ? Icons.close : Icons.search,
                                  color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _isSearching = !_isSearching;
                                  if (!_isSearching) {
                                    _searchController.clear();
                                    filteredSignalements =
                                        List<Map<String, dynamic>>.from(
                                            signalements);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Rechercher par titre, description ou arrondissement',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() {
                          _buttonScale = 0.95;
                        }),
                        onTapUp: (_) => setState(() {
                          _buttonScale = 1.0;
                          _showAddSignalementDialog();
                        }),
                        onTapCancel: () => setState(() {
                          _buttonScale = 1.0;
                        }),
                        child: AnimatedScale(
                          scale: _buttonScale,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.add,
                                      color: Colors.white,
                                      size: 30,
                                      weight: 700),
                                ),
                                const SizedBox(width: 10),
                                const Text('Ajouter un signalement',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Tous'),
                            Tab(text: 'Reçu'),
                            Tab(text: 'Rejeté'),
                            Tab(text: 'En attente'),
                            Tab(text: 'Traité')
                          ],
                          labelColor: Colors.green,
                          unselectedLabelColor: Colors.grey,
                          isScrollable: true,
                          indicatorColor: Colors.green,
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildSignalementList(filteredSignalements),
                              _buildSignalementList(filteredSignalements
                                  .where((s) => s['receptionStatus'] == 'Reçu')
                                  .toList()),
                              _buildSignalementList(filteredSignalements
                                  .where(
                                      (s) => s['receptionStatus'] == 'Rejeté')
                                  .toList()),
                              _buildSignalementList(filteredSignalements
                                  .where((s) =>
                                      s['traitementStatus'] == 'En attente')
                                  .toList()),
                              _buildSignalementList(filteredSignalements
                                  .where(
                                      (s) => s['traitementStatus'] == 'Traité')
                                  .toList()),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
