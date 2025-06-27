package com.citizenact.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class UserDTO {
    private Long id;

    @JsonProperty("username")
    private String username;

    @JsonProperty("email")
    private String email;

    @JsonProperty("role")
    private String role;

    @JsonProperty("status")
    private String status;

    @JsonProperty("arrondissementName")
    private String arrondissementName;

    @JsonProperty("arrondissementId")
    private Long arrondissementId;

    @JsonProperty("createdAt")
    private String createdAt; // ISO 8601 format, e.g., "2025-06-24T22:16:00Z"

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getArrondissementName() { return arrondissementName; }
    public void setArrondissementName(String arrondissementName) { this.arrondissementName = arrondissementName; }
    public Long getArrondissementId() { return arrondissementId; }
    public void setArrondissementId(Long arrondissementId) { this.arrondissementId = arrondissementId; }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}