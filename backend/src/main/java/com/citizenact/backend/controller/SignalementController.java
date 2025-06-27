package com.citizenact.backend.controller;

import com.citizenact.backend.dto.SignalementDTO;
import com.citizenact.backend.service.SignalementService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/signalements")
public class SignalementController {

    private final SignalementService signalementService;

    public SignalementController(SignalementService signalementService) {
        this.signalementService = signalementService;
    }

    @PostMapping
    public ResponseEntity<SignalementDTO> createSignalement(@RequestBody SignalementDTO signalementDTO) {
        return ResponseEntity.ok(signalementService.createSignalement(signalementDTO));
    }

    @GetMapping
    public ResponseEntity<List<SignalementDTO>> getAllSignalements() {
        return ResponseEntity.ok(signalementService.getAllSignalements());
    }

    @GetMapping("/user/{username}")
    public ResponseEntity<List<SignalementDTO>> getSignalementsByUser(@PathVariable String username) {
        return ResponseEntity.ok(signalementService.getSignalementsByUser(username));
    }

    @GetMapping("/arrondissement/{id}")
    public ResponseEntity<List<SignalementDTO>> getSignalementsByArrondissement(@PathVariable Long id) {
        return ResponseEntity.ok(signalementService.getSignalementsByArrondissementId(id));
    }

    @PutMapping("/{id}/traitement-status")
    public ResponseEntity<SignalementDTO> updateTraitementStatus(@PathVariable Long id, 
                                                                @RequestBody Map<String, String> request) {
        return ResponseEntity.ok(signalementService.updateTraitementStatus(id, request.get("traitementStatus")));
    }
}