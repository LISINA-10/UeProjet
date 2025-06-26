package com.citizenact.backend.service;

import com.citizenact.backend.dto.UserDTO;
import com.citizenact.backend.dto.UserRequest;
import com.citizenact.backend.entity.User;
import com.citizenact.backend.repository.UserRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final AuthenticationManager authenticationManager;
    private final NotificationService notificationService;

    public AuthService(UserRepository userRepository, AuthenticationManager authenticationManager, NotificationService notificationService) {
        this.userRepository = userRepository;
        this.authenticationManager = authenticationManager;
        this.notificationService = notificationService;
    }

    public UserDTO login(UserRequest userRequest) {
        SecurityContextHolder.clearContext();
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(userRequest.getUsername(), userRequest.getPassword())
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);
        User user = userRepository.findByUsername(userRequest.getUsername())
            .orElseThrow(() -> new RuntimeException("User not found after authentication"));
        return toDTO(user);
    }

    public UserDTO register(UserRequest userRequest) {
        if (userRequest.getUsername() == null || userRequest.getEmail() == null || userRequest.getPassword() == null) {
            throw new RuntimeException("Username, email, and password are required");
        }
        if (userRepository.findByUsername(userRequest.getUsername()).isPresent() ||
            userRepository.findByEmail(userRequest.getEmail()).isPresent()) {
            throw new RuntimeException("Username or email already exists");
        }
        if (userRequest.getRole() != null && !userRequest.getRole().equals("USER")) {
            throw new RuntimeException("Only USER role can be registered via this endpoint");
        }
        User user = new User();
        user.setUsername(userRequest.getUsername());
        user.setEmail(userRequest.getEmail());
        user.setPassword(userRequest.getPassword());
        user.setRole("USER");
        user.setStatus("ACTIVE");
        user.setArrondissementId(null);
        user = userRepository.save(user);
        notificationService.createRegistrationNotification(user.getId(), "Vous vous êtes inscrit avec succès");
        return toDTO(user);
    }

    private UserDTO toDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setRole(user.getRole());
        dto.setStatus(user.getStatus());
        dto.setArrondissementId(user.getArrondissementId());
        return dto;
    }
}