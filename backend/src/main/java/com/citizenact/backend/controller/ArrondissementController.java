package com.citizenact.backend.controller;

import com.citizenact.backend.dto.ArrondissementDTO;
import com.citizenact.backend.entity.Arrondissement;
import com.citizenact.backend.service.ArrondissementService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/arrondissements")
public class ArrondissementController {

    private final ArrondissementService arrondissementService;

    public ArrondissementController(ArrondissementService arrondissementService) {
        this.arrondissementService = arrondissementService;
    }

    @GetMapping
    public ResponseEntity<List<ArrondissementDTO>> getAllArrondissements() {
        return ResponseEntity.ok(arrondissementService.getAllArrondissements());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ArrondissementDTO> getArrondissementById(@PathVariable Long id) {
        return ResponseEntity.ok(arrondissementService.getArrondissementById(id));
    }

    @PostMapping
    public ResponseEntity<Arrondissement> createArrondissement(@RequestBody ArrondissementDTO arrondissementDTO) {
        return ResponseEntity.status(201).body(arrondissementService.createArrondissement(arrondissementDTO));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ArrondissementDTO> updateArrondissementStatus(@PathVariable Long id, @RequestBody String status) {
        return ResponseEntity.ok(arrondissementService.updateArrondissementStatus(id, status));
    }
}