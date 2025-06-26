package com.citizenact.backend.controller;

import com.citizenact.backend.dto.ArrondissementDTO;
import com.citizenact.backend.dto.SignalementDTO;
import com.citizenact.backend.dto.UserDTO;
import com.citizenact.backend.service.ArrondissementService;
import com.citizenact.backend.service.SignalementService;
import com.citizenact.backend.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/agent")
@PreAuthorize("hasRole('AGENT')")
public class AgentController {

    private final ArrondissementService arrondissementService;
    private final UserService userService;
    private final SignalementService signalementService;

    public AgentController(ArrondissementService arrondissementService, UserService userService, SignalementService signalementService) {
        this.arrondissementService = arrondissementService;
        this.userService = userService;
        this.signalementService = signalementService;
    }

    @GetMapping("/arrondissement/{id}")
    public ResponseEntity<ArrondissementDTO> getArrondissement(@PathVariable Long id) {
        return ResponseEntity.ok(arrondissementService.getArrondissementById(id));
    }

    @GetMapping("/user/{id}")
    public ResponseEntity<UserDTO> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @GetMapping("/signalements/arrondissement/{id}")
    public ResponseEntity<List<SignalementDTO>> getSignalementsByArrondissement(@PathVariable Long id) {
        return ResponseEntity.ok(signalementService.getSignalementsByArrondissementId(id));
    }

    @PutMapping("/signalements/{id}/traitement-status")
    public ResponseEntity<SignalementDTO> updateTraitementStatus(@PathVariable Long id, @RequestBody StatusUpdateDTO statusUpdate) {
        return ResponseEntity.ok(signalementService.updateTraitementStatus(id, statusUpdate.getStatus()));
    }

    // DTO pour la requête PUT
    public static class StatusUpdateDTO {
        private String status;

        public String getStatus() {
            return status;
        }

        public void setStatus(String status) {
            this.status = status;
        }
    }
}