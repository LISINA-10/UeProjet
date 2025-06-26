package com.citizenact.backend.controller;

import com.citizenact.backend.dto.UserDTO;
import com.citizenact.backend.dto.UserRequest;
import com.citizenact.backend.entity.User;
import com.citizenact.backend.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PutMapping("/profile")
    public ResponseEntity<UserDTO> updateProfile(@RequestBody UserRequest userRequest) {
        User user = userService.updateProfile(userRequest);
        return ResponseEntity.ok(toDTO(user));
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