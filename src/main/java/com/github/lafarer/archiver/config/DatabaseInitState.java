package com.github.lafarer.archiver.config;

import org.springframework.stereotype.Component;

@Component
public class DatabaseInitState {

    private boolean freshlyCreated = false;

    public boolean isFreshlyCreated() { return freshlyCreated; }

    public void markFreshlyCreated() { freshlyCreated = true; }
}
