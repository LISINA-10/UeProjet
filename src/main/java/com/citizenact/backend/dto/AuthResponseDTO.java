package com.citizenact.backend.dto;

public class AuthResponseDTO {
    private String message;

    public AuthResponseDTO(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}