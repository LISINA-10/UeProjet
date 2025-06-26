package com.citizenact.backend.repository;

import com.citizenact.backend.entity.Signalement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SignalementRepository extends JpaRepository<Signalement, Long> {
    List<Signalement> findByArrondissementId(Long arrondissementId);
    List<Signalement> findByUserId(Long userId);
    List<Signalement> findByUserIdAndArrondissementId(Long userId, Long arrondissementId);
}