import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'main_page.dart';
import '../widgets/custom_button.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _termsAccepted = false;
  double _scrollOffset = 0.0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Text(
                'Terms of License',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Welcome to the CitizenAct License Agreement.\n\n'
                'This application is designed to enable users to report the state of urban infrastructure and its cleanliness. By using CitizenAct, you agree to the following terms:\n\n'
                '1. **Purpose**: You may use this app to submit reports on the condition of roads, bridges, public spaces, and cleanliness levels in your area.\n'
                '2. **Data Usage**: All submitted data will be anonymized and used to improve urban planning and maintenance by local authorities.\n'
                '3. **User Responsibility**: Ensure all reports are accurate and respectful. Misuse or false reporting may result in account suspension.\n'
                '4. **Privacy**: Your personal information will be protected in accordance with our Privacy Policy.\n'
                '5. **Updates**: We may update this license periodically; continued use implies acceptance of the latest terms.\n\n'
                'By accepting, you agree to comply with these terms to contribute to a cleaner and better-maintained urban environment.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Accepter',
                onPressed: () {
                  setState(() {
                    _termsAccepted = true;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez accepter les termes de la licence.')),
      );
      return;
    }
    if (_emailController.text != _confirmEmailController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Les emails ne correspondent pas.')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Les mots de passe ne correspondent pas.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService().register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );
      print('Réponse JSON de register: $response');
      // Vérifier que l'utilisateur est un USER et ACTIVE
      if (response['role'] != 'USER') {
        throw Exception(
            'Seuls les utilisateurs avec le rôle USER peuvent s\'inscrire.');
      }
      if (response['status'] != 'ACTIVE') {
        throw Exception(
            'Votre compte est bloqué. Veuillez contacter l\'administrateur.');
      }
      final prefs = await SharedPreferences.getInstance();
      String username = response['username'] ?? _usernameController.text;
      await prefs.setString('username', username);
      print('Username stocké dans SharedPreferences: $username');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(
            username: username,
            userData: response,
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de l’inscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d’inscription: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/citizen_act_logo.svg',
                              height: 70,
                              width: 70,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Inscription',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SvgPicture.asset(
                      'assets/images/image_insc.svg',
                      height: constraints.maxHeight > 600 ? 250 : 170,
                      width: constraints.maxHeight > 600 ? 250 : 200,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 300),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 300),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 300),
                      child: TextField(
                        controller: _confirmEmailController,
                        decoration: InputDecoration(
                          labelText: 'Confirmer Email',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 300),
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 300),
                      child: TextField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirmer Password',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: _showLicenseDialog,
                          child: Text(
                            'Lisez les termes de la licence ici',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : CustomButton(
                            text: 'S\'inscrire',
                            onPressed: _register,
                          ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        'Vous avez déjà un compte ? Connectez-vous ici',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _scrollOffset > 100
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: Icon(Icons.arrow_upward),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}
