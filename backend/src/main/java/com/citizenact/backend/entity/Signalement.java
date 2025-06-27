package com.citizenact.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "signalements")
public class Signalement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "arrondissement_id", nullable = false)
    private Long arrondissementId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", nullable = false)
    private String description;

    @Column(name = "image_base64")
    private String imageBase64;

    @Column(name = "latitude", nullable = false)
    private Double latitude;

    @Column(name = "longitude", nullable = false)
    private Double longitude;

    @Column(name = "traitement_status", nullable = false)
    private String traitementStatus;

    @Column(name = "reception_status", nullable = false)
    private String receptionStatus;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    // Getters et Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getArrondissementId() { return arrondissementId; }
    public void setArrondissementId(Long arrondissementId) { this.arrondissementId = arrondissementId; }
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