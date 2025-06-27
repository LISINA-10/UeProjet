package com.citizenact.backend.controller;

import com.citizenact.backend.dto.ArrondissementDTO;
import com.citizenact.backend.dto.UserDTO;
import com.citizenact.backend.dto.UserRequest;
import com.citizenact.backend.entity.Arrondissement;
import com.citizenact.backend.entity.User;
import com.citizenact.backend.service.ArrondissementService;
import com.citizenact.backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final UserService userService;
    private final ArrondissementService arrondissementService;

    public AdminController(UserService userService, ArrondissementService arrondissementService) {
        this.userService = userService;
        this.arrondissementService = arrondissementService;
    }

    @PostMapping("/users/register")
    public ResponseEntity<?> registerAgent(@Valid @RequestBody UserRequest userRequest) {
        try {
            User user = userService.registerAgent(userRequest);
            return ResponseEntity.ok(toUserDTO(user));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse("Invalid user data: " + e.getMessage()));
        }
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserDTO>> getUsers() {
        List<User> users = userService.getUsersByRoleIn();
        List<UserDTO> userDTOs = users.stream().map(this::toUserDTO).collect(Collectors.toList());
        return ResponseEntity.ok(userDTOs);
    }

    @PutMapping("/users/{username}/status")
    public ResponseEntity<?> updateUserStatus(@PathVariable String username, @RequestBody UserRequest userRequest) {
        try {
            User user = userService.updateUserStatus(username, userRequest.getStatus());
            return ResponseEntity.ok(toUserDTO(user));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse("Invalid status update: " + e.getMessage()));
        }
    }

    @PostMapping("/arrondissements")
    public ResponseEntity<?> createArrondissement(@Valid @RequestBody ArrondissementDTO arrondissementDTO) {
        try {
            Arrondissement arrondissement = arrondissementService.createArrondissement(arrondissementDTO);
            return ResponseEntity.ok(arrondissement);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse("Invalid arrondissement data: " + e.getMessage()));
        }
    }

    @GetMapping("/arrondissements")
    public ResponseEntity<List<ArrondissementDTO>> getArrondissements() {
        return ResponseEntity.ok(arrondissementService.getAllArrondissements());
    }

    @PutMapping("/arrondissements/{id}/status")
    public ResponseEntity<?> updateArrondissementStatus(@PathVariable Long id, @RequestBody ArrondissementDTO arrondissementDTO) {
        try {
            ArrondissementDTO updated = arrondissementService.updateArrondissementStatus(id, arrondissementDTO.getStatus());
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse("Invalid arrondissement status update: " + e.getMessage()));
        }
    }

    private UserDTO toUserDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setRole(user.getRole());
        dto.setStatus(user.getStatus());
        dto.setArrondissementId(user.getArrondissementId());
        // Note: arrondissementName may need to be fetched from ArrondissementRepository if required
        // dto.setArrondissementName(...);
        dto.setCreatedAt(user.getCreatedAt() != null ? user.getCreatedAt().toString() : null);
        return dto;
    }
}

class ErrorResponse {
    private String message;

    public ErrorResponse(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}