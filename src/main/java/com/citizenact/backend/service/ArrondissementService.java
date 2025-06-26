package com.citizenact.backend.service;

import com.citizenact.backend.dto.ArrondissementDTO;
import com.citizenact.backend.entity.Arrondissement;
import com.citizenact.backend.repository.ArrondissementRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class ArrondissementService {

    private final ArrondissementRepository arrondissementRepository;
    private final UserService userService;
    private final ObjectMapper objectMapper;

    public ArrondissementService(ArrondissementRepository arrondissementRepository, UserService userService, ObjectMapper objectMapper) {
        this.arrondissementRepository = arrondissementRepository;
        this.userService = userService;
        this.objectMapper = objectMapper;
    }

    public Arrondissement createArrondissement(ArrondissementDTO dto) {
        try {
            // Validate GeoJSON string
            if (dto.getGeo() == null || dto.getGeo().isEmpty()) {
                throw new IllegalArgumentException("GeoJSON string is required");
            }
            // Parse geo string to validate
            Map<String, Object> geo;
            try {
                geo = objectMapper.readValue(dto.getGeo(), Map.class);
            } catch (Exception e) {
                throw new IllegalArgumentException("Invalid GeoJSON: " + e.getMessage());
            }
            if (!"Polygon".equals(geo.get("type"))) {
                throw new IllegalArgumentException("Invalid GeoJSON: type must be 'Polygon'");
            }
            if (!(geo.get("coordinates") instanceof List)) {
                throw new IllegalArgumentException("Invalid GeoJSON: coordinates must be a list");
            }
            List<List<List<Double>>> coordinates = (List<List<List<Double>>>) geo.get("coordinates");
            if (coordinates.isEmpty() || coordinates.get(0).size() < 4) {
                throw new IllegalArgumentException("Invalid GeoJSON: Polygon must have at least 4 points (including closing point)");
            }
            List<List<Double>> ring = coordinates.get(0);
            List<Double> firstPoint = ring.get(0);
            List<Double> lastPoint = ring.get(ring.size() - 1);
            if (!firstPoint.get(0).equals(lastPoint.get(0)) || !firstPoint.get(1).equals(lastPoint.get(1))) {
                throw new IllegalArgumentException("Invalid GeoJSON: Polygon must be closed (first and last points must match)");
            }

            Arrondissement arrondissement = new Arrondissement();
            arrondissement.setName(dto.getName());
            arrondissement.setCountry(dto.getCountry());
            arrondissement.setRegion(dto.getRegion());
            arrondissement.setStatus(dto.getStatus());
            arrondissement.setGeo(dto.getGeo());
            arrondissement.setArea(dto.getArea());
            arrondissement.setCentroid(dto.getCentroid());
            return arrondissementRepository.save(arrondissement);
        } catch (Exception e) {
            throw new IllegalArgumentException("Failed to create arrondissement: " + e.getMessage());
        }
    }

    public ArrondissementDTO getArrondissementById(Long id) {
        Arrondissement arrondissement = arrondissementRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Arrondissement not found with ID: " + id));
        return toDTO(arrondissement);
    }

    public List<ArrondissementDTO> getAllArrondissements() {
        return arrondissementRepository.findAll().stream()
                .sorted((a, b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
                .map(this::toDTO)
                .toList();
    }

    public ArrondissementDTO updateArrondissementStatus(Long id, String status) {
        Arrondissement arrondissement = arrondissementRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Arrondissement not found"));
        if (!"ACTIVE".equals(status) && !"INACTIVE".equals(status)) {
            throw new IllegalArgumentException("Status must be ACTIVE or INACTIVE");
        }
        arrondissement.setStatus(status);
        arrondissement = arrondissementRepository.save(arrondissement);
        userService.updateAgentsStatusByArrondissement(id, status);
        return toDTO(arrondissement);
    }

    private ArrondissementDTO toDTO(Arrondissement arrondissement) {
        ArrondissementDTO dto = new ArrondissementDTO();
        dto.setId(arrondissement.getId());
        dto.setName(arrondissement.getName());
        dto.setCountry(arrondissement.getCountry());
        dto.setRegion(arrondissement.getRegion());
        dto.setStatus(arrondissement.getStatus());
        dto.setGeo(arrondissement.getGeo());
        dto.setArea(arrondissement.getArea());
        dto.setCentroid(arrondissement.getCentroid());
        dto.setCreatedAt(arrondissement.getCreatedAt() != null ? arrondissement.getCreatedAt().toString() : null);
        return dto;
    }
}