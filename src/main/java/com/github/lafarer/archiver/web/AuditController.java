package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.service.StorageAuditService;
import com.github.lafarer.archiver.service.StorageAuditService.AuditReport;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.io.IOException;

@Controller
@RequestMapping("/audit")
@RequiredArgsConstructor
@Slf4j
public class AuditController {

    private final StorageAuditService auditService;

    @GetMapping
    public String index(@RequestParam(defaultValue = "false") boolean run,
                        Model model) throws IOException {
        AuditReport report = null;
        if (run) {
            report = auditService.scan();
        }
        model.addAttribute("report", report);
        model.addAttribute("page", "audit");
        return "audit/index";
    }
}
