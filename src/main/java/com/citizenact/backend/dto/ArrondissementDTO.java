package com.citizenact.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class ArrondissementDTO {
    private Long id;

    @JsonProperty("name")
    @NotBlank(message = "Name is required")
    private String name;

    @JsonProperty("country")
    @NotBlank(message = "Country is required")
    private String country;

    @JsonProperty("region")
    @NotBlank(message = "Region is required")
    private String region;

    @JsonProperty("status")
    @NotBlank(message = "Status is required")
    private String status;

    @JsonProperty("geo")
    @NotBlank(message = "GeoJSON string is required")
    private String geo;

    @JsonProperty("area")
    @NotNull(message = "Area is required")
    private Double area;

    @JsonProperty("centroid")
    @NotNull(message = "Centroid is required")
    private Double[] centroid;

    @JsonProperty("createdAt")
    private String createdAt;

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
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}