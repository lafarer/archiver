package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.service.WatchdogService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice
@RequiredArgsConstructor
public class GlobalModelAdvice {

    private final WatchdogService watchdogService;

    @ModelAttribute("watchdogRunning")
    public boolean watchdogRunning() {
        return watchdogService.isRunning();
    }

    @ModelAttribute("contextPath")
    public String contextPath(HttpServletRequest request) {
        return request.getContextPath();
    }
}
