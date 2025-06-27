package com.citizenact.backend.repository;

import com.citizenact.backend.entity.Arrondissement;
import com.citizenact.backend.entity.User;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ArrondissementRepository extends JpaRepository<Arrondissement, Long> {

    Optional<User> findById(Integer arrondissementId);
}