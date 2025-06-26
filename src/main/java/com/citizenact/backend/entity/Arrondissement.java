package com.citizenact.backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "arrondissements")
public class Arrondissement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "country", nullable = false)
    private String country;

    @Column(name = "region", nullable = false)
    private String region;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "geo", columnDefinition = "TEXT")
    private String geo;

    @Column(name = "area")
    private Double area;

    @Column(name = "centroid")
    private Double[] centroid;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getGeo() { return geo; }
    public void setGeo(String geo) { this.geo = geo; }
    public Double getArea() { return area; }
    public void setArea(Double area) { this.area = area; }
    public Double[] getCentroid() { return centroid; }
    public void setCentroid(Double[] centroid) { this.centroid = centroid; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}