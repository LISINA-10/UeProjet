package com.citizenact.backend.dto;

import java.time.LocalDateTime;

public class SignalementDTO {
    private Long id;
    private Long userId;
    private String username;
    private Long arrondissementId;
    private String arrondissementName;
    private String title;
    private String description;
    private String imageBase64;
    private Double latitude;
    private Double longitude;
    private String traitementStatus;
    private String receptionStatus;
    private LocalDateTime createdAt;

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public Long getArrondissementId() { return arrondissementId; }
    public void setArrondissementId(Long arrondissementId) { this.arrondissementId = arrondissementId; }
    public String getArrondissementName() { return arrondissementName; }
    public void setArrondissementName(String arrondissementName) { this.arrondissementName = arrondissementName; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getImageBase64() { return imageBase64; }
    public void setImageBase64(String imageBase64) { this.imageBase64 = imageBase64; }
    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public String getTraitementStatus() { return traitementStatus; }
    public void setTraitementStatus(String traitementStatus) { this.traitementStatus = traitementStatus; }
    public String getReceptionStatus() { return receptionStatus; }
    public void setReceptionStatus(String receptionStatus) { this.receptionStatus = receptionStatus; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}