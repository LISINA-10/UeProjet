package com.citizenact.backend.controller;

import com.citizenact.backend.dto.UserDTO;
import com.citizenact.backend.dto.UserRequest;
import com.citizenact.backend.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<UserDTO> login(@RequestBody UserRequest userRequest) {
        return ResponseEntity.ok(authService.login(userRequest));
    }

    @PostMapping("/register")
    public ResponseEntity<UserDTO> register(@RequestBody UserRequest userRequest) {
        return ResponseEntity.ok(authService.register(userRequest));
    }
}