package com.citizenact.backend.dto;

import java.util.List;

public class UpdateSignalementStatusDTO {
    private List<Long> signalementIds;
    private String traitementStatus;
    private String receptionStatus;

    public List<Long> getSignalementIds() {
        return signalementIds;
    }

    public void setSignalementIds(List<Long> signalementIds) {
        this.signalementIds = signalementIds;
    }

    public String getTraitementStatus() {
        return traitementStatus;
    }

    public void setTraitementStatus(String traitementStatus) {
        this.traitementStatus = traitementStatus;
    }

    public String getReceptionStatus() {
        return receptionStatus;
    }

    public void setReceptionStatus(String receptionStatus) {
        this.receptionStatus = receptionStatus;
    }
}