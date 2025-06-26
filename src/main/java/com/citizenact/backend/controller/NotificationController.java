package com.citizenact.backend.controller;

import com.citizenact.backend.dto.NotificationDTO;
import com.citizenact.backend.service.NotificationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<List<NotificationDTO>> getUserNotifications(
            @RequestHeader("X-Username") String username) {
        return ResponseEntity.ok(notificationService.getUserNotifications(username));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<NotificationDTO> markNotificationAsRead(
            @PathVariable Long id, @RequestHeader("X-Username") String username) {
        return ResponseEntity.ok(notificationService.markNotificationAsRead(id, username));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteNotification(
            @PathVariable Long id, @RequestHeader("X-Username") String username) {
        notificationService.deleteNotification(id, username);
        return ResponseEntity.ok().build();
    }

    @PostMapping
    public ResponseEntity<Void> createNotification(
            @RequestHeader("X-Username") String username,
            @RequestBody NotificationDTO notificationDTO) {
        notificationService.createNotification(
            notificationDTO.getUserId(),
            notificationDTO.getSignalementId(),
            notificationDTO.getMessage()
        );
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}