package com.citizenact.backend.service;

import com.citizenact.backend.dto.UserDTO;
import com.citizenact.backend.dto.UserRequest;
import com.citizenact.backend.entity.User;
import com.citizenact.backend.repository.ArrondissementRepository;
import com.citizenact.backend.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final ArrondissementRepository arrondissementRepository;
    private final NotificationService notificationService;

    public UserService(UserRepository userRepository, ArrondissementRepository arrondissementRepository, NotificationService notificationService) {
        this.userRepository = userRepository;
        this.arrondissementRepository = arrondissementRepository;
        this.notificationService = notificationService;
    }

    public User registerAgent(UserRequest userRequest) {
        if (userRequest.getUsername() == null || userRequest.getEmail() == null || userRequest.getPassword() == null) {
            throw new IllegalArgumentException("Invalid user registration: username, email, and password are required");
        }
        if (userRepository.findByUsername(userRequest.getUsername()).isPresent() ||
            userRepository.findByEmail(userRequest.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Invalid user registration: username or email already exists");
        }
        if (!"AGENT".equals(userRequest.getRole())) {
            throw new IllegalArgumentException("Invalid user registration: role must be AGENT");
        }
        if (userRequest.getArrondissementId() == null || !arrondissementRepository.existsById(userRequest.getArrondissementId())) {
            throw new IllegalArgumentException("Invalid user registration: valid arrondissementId required");
        }
        User user = new User();
        user.setUsername(userRequest.getUsername());
        user.setEmail(userRequest.getEmail());
        user.setPassword(userRequest.getPassword());
        user.setRole("AGENT");
        user.setStatus("ACTIVE");
        user.setArrondissementId(userRequest.getArrondissementId());
        return userRepository.save(user);
    }

    public UserDTO getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("User not found with ID: " + id));
        return toDTO(user);
    }

    public User updateProfile(UserRequest userRequest) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
        if (userRequest.getEmail() != null) {
            if (userRepository.findByEmail(userRequest.getEmail()).isPresent() &&
                !userRequest.getEmail().equals(user.getEmail())) {
                throw new IllegalArgumentException("Email already in use");
            }
            user.setEmail(userRequest.getEmail());
        }
        if (userRequest.getPassword() != null) {
            user.setPassword(userRequest.getPassword());
        }
        user = userRepository.save(user);
        if ("USER".equals(user.getRole())) {
            notificationService.createRegistrationNotification(user.getId(), "Votre profil a été mis à jour");
        }
        return user;
    }

    public User updateUserStatus(String username, String status) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
        if (!status.equals("ACTIVE") && !status.equals("BLOCKED")) {
            throw new IllegalArgumentException("Invalid status: " + status);
        }
        if (status.equals("ACTIVE") && user.getRole().equals("AGENT") && user.getArrondissementId() != null) {
            arrondissementRepository.findById(user.getArrondissementId())
                .filter(arr -> arr.getStatus().equals("ACTIVE"))
                .orElseThrow(() -> new IllegalArgumentException("Cannot activate agent: associated arrondissement is INACTIVE or does not exist"));
        }
        user.setStatus(status);
        user = userRepository.save(user);
        if ("USER".equals(user.getRole())) {
            notificationService.createRegistrationNotification(user.getId(), "Votre statut a été mis à jour à : " + status);
        }
        return user;
    }

    public void updateAgentsStatusByArrondissement(Long arrondissementId, String arrondissementStatus) {
        List<User> agents = userRepository.findByArrondissementIdAndRole(arrondissementId, "AGENT");
        for (User agent : agents) {
            if (arrondissementStatus.equals("INACTIVE")) {
                agent.setStatus("BLOCKED");
                userRepository.save(agent);
            }
        }
    }

    public List<User> getUsersByRoleIn() {
        return userRepository.findAllByRoleIn(Arrays.asList("USER", "AGENT"));
    }

    private UserDTO toDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setRole(user.getRole());
        dto.setStatus(user.getStatus());
        dto.setArrondissementId(user.getArrondissementId());
        dto.setCreatedAt(user.getCreatedAt() != null ? user.getCreatedAt().toString() : null);
        return dto;
    }
}