package com.citizenact.backend.service;

import com.citizenact.backend.dto.NotificationDTO;
import com.citizenact.backend.entity.Notification;
import com.citizenact.backend.repository.NotificationRepository;
import com.citizenact.backend.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationService(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    public void createNotification(Long userId, Long signalementId, String message) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setSignalementId(signalementId);
        notification.setMessage(message);
        notification.setRead(false);
        notificationRepository.save(notification);
    }

    public void createRegistrationNotification(Long userId, String message) {
        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setSignalementId(null);
        notification.setMessage(message);
        notification.setRead(false);
        notificationRepository.save(notification);
    }

    public List<NotificationDTO> getUserNotifications(String username) {
        Long userId = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found: " + username))
            .getId();
        return notificationRepository.findByUserId(userId).stream()
            .map(this::toDTO)
            .collect(Collectors.toList());
    }

    public NotificationDTO markNotificationAsRead(Long notificationId, String username) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new RuntimeException("Notification not found: " + notificationId));
        Long userId = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found: " + username))
            .getId();
        if (!notification.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized access to notification: " + notificationId);
        }
        notification.setRead(true);
        notification = notificationRepository.save(notification);
        return toDTO(notification);
    }

    public void deleteNotification(Long notificationId, String username) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new RuntimeException("Notification not found: " + notificationId));
        Long userId = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("User not found: " + username))
            .getId();
        if (!notification.getUserId().equals(userId)) {
            throw new RuntimeException("Unauthorized access to notification: " + notificationId);
        }
        notificationRepository.delete(notification);
    }

    private NotificationDTO toDTO(Notification notification) {
        NotificationDTO dto = new NotificationDTO();
        dto.setId(notification.getId());
        dto.setUserId(notification.getUserId());
        dto.setSignalementId(notification.getSignalementId());
        dto.setMessage(notification.getMessage());
        dto.setIsRead(notification.isRead());
        dto.setCreatedAt(notification.getCreatedAt());
        return dto;
    }
}