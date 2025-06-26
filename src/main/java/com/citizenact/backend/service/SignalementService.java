package com.citizenact.backend.service;



import com.citizenact.backend.dto.SignalementDTO;

import com.citizenact.backend.entity.Signalement;

import com.citizenact.backend.entity.User;

import com.citizenact.backend.repository.ArrondissementRepository;

import com.citizenact.backend.repository.SignalementRepository;

import com.citizenact.backend.repository.UserRepository;

import org.slf4j.Logger;

import org.slf4j.LoggerFactory;

import org.springframework.security.core.context.SecurityContextHolder;

import org.springframework.stereotype.Service;



import java.time.LocalDateTime;

import java.util.Arrays;

import java.util.Base64;

import java.util.List;

import java.util.stream.Collectors;



@Service

public class SignalementService {



    private static final Logger logger = LoggerFactory.getLogger(SignalementService.class);

    private final SignalementRepository signalementRepository;

    private final UserRepository userRepository;

    private final ArrondissementRepository arrondissementRepository;

    private final NotificationService notificationService;

    private static final List<String> VALID_RECEPTION_STATUSES = Arrays.asList("Reçu", "Rejeté");

    private static final List<String> VALID_TRAITEMENT_STATUSES = Arrays.asList("En attente", "Traité");



    public SignalementService(SignalementRepository signalementRepository, UserRepository userRepository,

                             ArrondissementRepository arrondissementRepository, NotificationService notificationService) {

        this.signalementRepository = signalementRepository;

        this.userRepository = userRepository;

        this.arrondissementRepository = arrondissementRepository;

        this.notificationService = notificationService;

    }



    public SignalementDTO createSignalement(SignalementDTO signalementDTO) {

        String username = SecurityContextHolder.getContext().getAuthentication().getName();

        User user = userRepository.findByUsername(username)

                .orElseThrow(() -> {

                    logger.error("User not found: {}", username);

                    return new IllegalArgumentException("User not found: " + username);

                });



        if (!"USER".equals(user.getRole())) {

            logger.warn("User {} attempted to create signalement with invalid role: {}", username, user.getRole());

            throw new IllegalArgumentException("Only users with role USER can create signalements");

        }



        // Validate arrondissement

        if (!arrondissementRepository.existsById(signalementDTO.getArrondissementId())) {

            logger.error("Arrondissement not found with ID: {}", signalementDTO.getArrondissementId());

            throw new IllegalArgumentException("Arrondissement not found with ID: " + signalementDTO.getArrondissementId());

        }



        // Validate reception status

        if (signalementDTO.getReceptionStatus() == null || !VALID_RECEPTION_STATUSES.contains(signalementDTO.getReceptionStatus())) {

            logger.error("Invalid reception status: {}", signalementDTO.getReceptionStatus());

            throw new IllegalArgumentException("Reception status must be one of: " + String.join(", ", VALID_RECEPTION_STATUSES));

        }



        // Validate Base64 image if provided

        String base64Image = signalementDTO.getImageBase64();

        if (base64Image != null && !base64Image.isEmpty()) {

            try {

                // Clean MIME prefix if present

                String cleanedBase64 = base64Image.replaceFirst("^data:image/[^;]+;base64,", "");

                // Validate Base64

                Base64.getDecoder().decode(cleanedBase64);

                logger.debug("Base64 image validated successfully for signalement");

            } catch (IllegalArgumentException e) {

                logger.error("Invalid Base64 format: {}", e.getMessage());

                throw new IllegalArgumentException("Invalid Base64 image format: " + e.getMessage());

            }

        } else {

            logger.debug("No image provided for signalement, setting imageBase64 to null");

            signalementDTO.setImageBase64(null); // Explicitly set to null if no image

        }



        // Create signalement entity

        Signalement signalement = new Signalement();

        signalement.setUserId(user.getId());

        signalement.setArrondissementId(signalementDTO.getArrondissementId());

        signalement.setTitle(signalementDTO.getTitle());

        signalement.setDescription(signalementDTO.getDescription());

        signalement.setImageBase64(signalementDTO.getImageBase64());

        signalement.setLatitude(signalementDTO.getLatitude());

        signalement.setLongitude(signalementDTO.getLongitude());

        signalement.setTraitementStatus("En attente");

        signalement.setReceptionStatus(signalementDTO.getReceptionStatus());

        signalement.setCreatedAt(LocalDateTime.now());



        try {

            Signalement savedSignalement = signalementRepository.save(signalement);

            logger.info("Signalement saved with ID: {}", savedSignalement.getId());

            notificationService.createNotification(user.getId(), savedSignalement.getId(),

                    "Signalement créé: " + signalement.getTitle());

            return toDTO(savedSignalement, user);

        } catch (Exception e) {

            logger.error("Error saving signalement: {}", e.getMessage(), e);

            throw new RuntimeException("Failed to save signalement: " + e.getMessage());

        }

    }



    public List<SignalementDTO> getAllSignalements() {

        String username = SecurityContextHolder.getContext().getAuthentication().getName();

        User currentUser = userRepository.findByUsername(username)

                .orElseThrow(() -> {

                    logger.error("User not found: {}", username);

                    return new IllegalArgumentException("User not found");

                });



        if ("ADMIN".equals(currentUser.getRole())) {

            logger.warn("Admin {} attempted to access signalements", username);

            throw new IllegalArgumentException("Admins cannot access signalements");

        }



        List<Signalement> signalements;

        if ("AGENT".equals(currentUser.getRole())) {

            Long arrondissementId = currentUser.getArrondissementId();

            if (arrondissementId == null) {

                logger.error("Agent {} is not associated with an arrondissement", username);

                throw new IllegalArgumentException("Agent must be associated with an arrondissement");

            }

            signalements = signalementRepository.findByArrondissementId(arrondissementId);

        } else {

            signalements = signalementRepository.findAll();

        }



        return signalements.stream()

                .map(signalement -> {

                    User signalementUser = userRepository.findById(signalement.getUserId())

                            .orElseThrow(() -> {

                                logger.error("Signalement user not found: {}", signalement.getUserId());

                                return new IllegalArgumentException("Signalement user not found");

                            });

                    return toDTO(signalement, signalementUser);

                })

                .collect(Collectors.toList());

    }



    public List<SignalementDTO> getSignalementsByUser(String username) {

        String currentUsername = SecurityContextHolder.getContext().getAuthentication().getName();

        User currentUser = userRepository.findByUsername(currentUsername)

                .orElseThrow(() -> {

                    logger.error("Current user not found: {}", currentUsername);

                    return new IllegalArgumentException("Current user not found");

                });

        User targetUser = userRepository.findByUsername(username)

                .orElseThrow(() -> {

                    logger.error("Target user not found: {}", username);

                    return new IllegalArgumentException("Target user not found");

                });



        if ("ADMIN".equals(currentUser.getRole())) {

            logger.warn("Admin {} attempted to access signalements", currentUsername);

            throw new IllegalArgumentException("Admins cannot access signalements");

        }



        if ("USER".equals(currentUser.getRole()) && !currentUsername.equals(username)) {

            logger.warn("User {} attempted to access signalements of user {}", currentUsername, username);

            throw new IllegalArgumentException("Users can only view their own signalements");

        }



        List<Signalement> signalements;

        if ("AGENT".equals(currentUser.getRole())) {

            Long arrondissementId = currentUser.getArrondissementId();

            if (arrondissementId == null) {

                logger.error("Agent {} is not associated with an arrondissement", currentUsername);

                throw new IllegalArgumentException("Agent must be associated with an arrondissement");

            }

            signalements = signalementRepository.findByUserIdAndArrondissementId(targetUser.getId(), arrondissementId);

        } else {

            signalements = signalementRepository.findByUserId(targetUser.getId());

        }



        return signalements.stream()

                .map(signalement -> toDTO(signalement, targetUser))

                .collect(Collectors.toList());

    }



    public List<SignalementDTO> getSignalementsByArrondissementId(Long arrondissementId) {

        String username = SecurityContextHolder.getContext().getAuthentication().getName();

        User currentUser = userRepository.findByUsername(username)

                .orElseThrow(() -> {

                    logger.error("User not found: {}", username);

                    return new IllegalArgumentException("User not found");

                });



        if ("ADMIN".equals(currentUser.getRole())) {

            logger.warn("Admin {} attempted to access signalements", username);

            throw new IllegalArgumentException("Admins cannot access signalements");

        }



        if ("AGENT".equals(currentUser.getRole()) && !arrondissementId.equals(currentUser.getArrondissementId())) {

            logger.warn("Agent {} attempted to access signalements outside their arrondissement {}", username, arrondissementId);

            throw new IllegalArgumentException("Agent can only access signalements in their arrondissement");

        }



        if (!arrondissementRepository.existsById(arrondissementId)) {

            logger.error("Arrondissement not found with ID: {}", arrondissementId);

            throw new IllegalArgumentException("Arrondissement not found with ID: " + arrondissementId);

        }



        List<Signalement> signalements = signalementRepository.findByArrondissementId(arrondissementId);

        return signalements.stream()

                .map(signalement -> {

                    User signalementUser = userRepository.findById(signalement.getUserId())

                            .orElseThrow(() -> {

                                logger.error("Signalement user not found: {}", signalement.getUserId());

                                return new IllegalArgumentException("Signalement user not found");

                            });

                    return toDTO(signalement, signalementUser);

                })

                .collect(Collectors.toList());

    }



    public SignalementDTO updateTraitementStatus(Long id, String traitementStatus) {

        String username = SecurityContextHolder.getContext().getAuthentication().getName();

        User user = userRepository.findByUsername(username)

                .orElseThrow(() -> {

                    logger.error("User not found: {}", username);

                    return new IllegalArgumentException("User not found");

                });



        if ("ADMIN".equals(user.getRole())) {

            logger.warn("Admin {} attempted to update signalement status", username);

            throw new IllegalArgumentException("Admins cannot update signalements");

        }



        if (!"AGENT".equals(user.getRole())) {

            logger.warn("User {} with role {} attempted to update signalement status", username, user.getRole());

            throw new IllegalArgumentException("Only agents can update traitement status");

        }



        if (!VALID_TRAITEMENT_STATUSES.contains(traitementStatus)) {

            logger.error("Invalid traitement status: {}", traitementStatus);

            throw new IllegalArgumentException("Traitement status must be one of: " + String.join(", ", VALID_TRAITEMENT_STATUSES));

        }



        Signalement signalement = signalementRepository.findById(id)

                .orElseThrow(() -> {

                    logger.error("Signalement not found with ID: {}", id);

                    return new IllegalArgumentException("Signalement not found");

                });



        if (!signalement.getArrondissementId().equals(user.getArrondissementId())) {

            logger.warn("Agent {} attempted to update signalement outside their arrondissement", username);

            throw new IllegalArgumentException("Agent can only update signalements in their arrondissement");

        }



        signalement.setTraitementStatus(traitementStatus);

        Signalement updatedSignalement = signalementRepository.save(signalement);



        User signalementUser = userRepository.findById(signalement.getUserId())

                .orElseThrow(() -> {

                    logger.error("Signalement user not found: {}", signalement.getUserId());

                    return new IllegalArgumentException("Signalement user not found");

                });

        notificationService.createNotification(signalementUser.getId(), updatedSignalement.getId(),

                "Signalement status updated to: " + traitementStatus);



        return toDTO(updatedSignalement, signalementUser);

    }



    private SignalementDTO toDTO(Signalement signalement, User signalementUser) {

        String currentUsername = SecurityContextHolder.getContext().getAuthentication().getName();

        User currentUser = userRepository.findByUsername(currentUsername)

                .orElseThrow(() -> {

                    logger.error("Current user not found: {}", currentUsername);

                    return new IllegalArgumentException("Current user not found");

                });



        SignalementDTO dto = new SignalementDTO();

        dto.setId(signalement.getId());

        dto.setArrondissementId(signalement.getArrondissementId());

        dto.setTitle(signalement.getTitle());

        dto.setDescription(signalement.getDescription());

        dto.setImageBase64(signalement.getImageBase64());

        dto.setLatitude(signalement.getLatitude());

        dto.setLongitude(signalement.getLongitude());

        dto.setTraitementStatus(signalement.getTraitementStatus());

        dto.setReceptionStatus(signalement.getReceptionStatus());

        dto.setCreatedAt(signalement.getCreatedAt());



        if ("AGENT".equals(currentUser.getRole())) {

            dto.setUsername(signalementUser.getUsername());

        }



        // Include arrondissement name for frontend

        arrondissementRepository.findById(signalement.getArrondissementId())

                .ifPresent(arrondissement -> dto.setArrondissementName(arrondissement.getName()));



        return dto;

    }

}