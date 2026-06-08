---
inclusion: manual
---

# Skill Selection Matrix — Targeted Skill Loading

**Purpose:** Instead of "read ALL skills for a role," load ONLY the 2-4 skill files relevant to the current task. This cuts token usage by 60-80% while maintaining depth where it matters.

**Rule:** When a role activates, the orchestrator selects skills based on the ACTIVITY being performed, not just the role name. A role may have 8-20 skill files but only 2-4 are relevant to any given task.

---

## THINK PHASE — Skill Selection

### market_researcher
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Full market research (first time) | ALL 5 files | none |
| Competitive analysis only | competitive_teardown.md, positioning_april_dunford.md | others |
| Sizing only | market_sizing_tam_sam_som.md | others |
| Persona/JTBD focus | jtbd_interviews.md, positioning_april_dunford.md | others |

### cto
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Full strategy (first time) | ALL 6 files | none |
| Build-vs-buy decision | build_vs_buy_evaluation.md, tech_stack_selection.md | others |
| Tech debt discussion | technical_debt_strategy.md, tech_strategy_framework.md | others |
| Org design question | engineering_org_design.md | others |

---

## DESIGN PHASE — Skill Selection

### product_manager
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Full PRD creation | prd_authoring.md, user_story_authoring.md, mvp_scope_definition.md | experiment, okrs, rice, north_star |
| Story writing only | user_story_authoring.md | others |
| Prioritization | rice_prioritization.md, north_star_metric.md | others |
| Scope definition | mvp_scope_definition.md, okrs_framework.md | others |

### architect
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Full system design | microservices_decomposition.md, domain_driven_design.md, project_structure_layout.md | others load on-demand |
| ADR writing | adr_authoring.md | others |
| Event-driven design | event_sourcing_cqrs.md, consistency_models_cap.md | others |
| Capacity planning | capacity_planning.md | others |
| Security architecture | stride_threat_modeling.md | others |
| Monolith design | domain_driven_design.md, project_structure_layout.md | microservices, event_sourcing |

### database_architect
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Initial schema design | normalization_vs_denormalization.md, index_design_query_plans.md, multi_tenancy_patterns.md | others |
| Migration planning | migration_strategies_online_offline.md | others |
| Scaling decisions | sharding_partitioning_strategies.md, read_replica_topology.md | others |
| Compliance/GDPR | retention_and_gdpr_deletion.md | others |
| Time-series data | time_series_schema_design.md | others |
| Data lake/warehouse | data_lake_lakehouse_design.md, olap_oltp_boundaries.md, cloud_data_pipelines_aws_azure_gcp.md | others |

### cloud_architect
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Initial cloud design | vpc_network_topology.md, landing_zone_design.md, iam_boundary_policies.md | others |
| Multi-region setup | multi_region_strategy.md, capacity_planning_quotas_limits.md | others |
| Cost optimization | finops_baseline.md | others |
| Security review | security_review_drives.md, iam_boundary_policies.md | others |
| Regulated industry | regulated_industry_architectures.md, well_architected_framework.md | others |

### finops_architect
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Initial cost model | cost_modeling_unit_economics.md, commitments_savings_plans_strategy.md | others |
| Budget alerts setup | anomaly_detection_budget_alerts.md | others |
| Chargeback model | chargeback_showback_models.md | others |
| Quarterly review | optimization_roadmap_quarterly.md | others |

### security_engineer (DESIGN pass)
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Threat modeling | threat_modeling_stride_pasta.md, zero_trust_architecture.md | others |
| Auth design | auth_design.md, identity_access_management_rbac_abac.md | others |
| Compliance mapping | compliance_soc2_iso_hipaa_pci.md, privacy_engineering_gdpr_ccpa.md | others |
| Data security | data_security_encryption_classification.md, cryptography_pki_key_management.md | others |

### scrum_master
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Pre-build gate | prebuild_documentation_gate.md, sprint_planning.md | others |
| Sprint planning | sprint_planning.md, velocity_capacity_modeling.md, estimation_techniques.md | others |
| Retrospective | retrospective_facilitation.md | others |
| Blocker handling | blocker_triage.md | others |

---

## DEVELOP PHASE — Skill Selection

### backend_lead
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| API implementation plan | api_versioning.md, rate_limiting_algorithms.md, idempotency_patterns.md | others |
| Distributed systems | saga_pattern_distributed_transactions.md, outbox_pattern_event_publishing.md, circuit_breaker_bulkhead.md | others |
| Performance optimization | caching_strategies.md, rate_limiting_algorithms.md | others |
| Integration design | integration_contract_spec.md | others |
| Schema work | database_schema_design.md | others |

### frontend_lead
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Component architecture | component_decomposition.md, state_management_patterns.md | others |
| React/Next.js project | modern_react_nextjs_patterns.md, component_decomposition.md | others |
| Accessibility | wcag_accessibility.md | others |
| Performance | core_web_vitals.md | others |
| Design system | design_system_governance.md | others |
| Mobile strategy | mobile_development_strategy.md | others |

### senior_engineer_be
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Writing new feature code | tdd_red_green_refactor.md, error_handling_strategies.md | others |
| Fixing bugs | debugging_methodology.md, error_handling_strategies.md | others |
| Code review | code_review_excellence.md | others |
| Concurrency work | concurrency_safety.md | others |
| Refactoring | refactoring_safely.md | others |
| Feature flags | feature_flags_safely.md | others |
| Performance issue | performance_profiling.md | others |

### senior_engineer_fe
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Writing new feature code | tdd_red_green_refactor.md, error_handling_strategies.md | others |
| Fixing bugs | debugging_methodology.md, error_handling_strategies.md | others |
| Code review | code_review_excellence.md | others |
| Performance issue | performance_profiling.md | others |
| Refactoring | refactoring_safely.md | others |
| Feature flags | feature_flags_safely.md | others |

### ml_engineer
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| RAG system | vector_search_rag_architecture.md, production_rag_at_scale.md, contextual_retrieval.md | others |
| Agent design | agent_design_tool_use.md, prompt_engineering_production.md | others |
| Memory system | agentic_memory_mem0.md, long_term_memory_systems.md, semantic_caching.md | others |
| MLOps/deployment | mlops_pipelines_deployment.md, ai_ml_testing_evals.md | others |
| Full ML system design | ai_ml_system_design.md, mlops_pipelines_deployment.md | others |
| Prompt optimization | prompt_optimization_dspy.md, prompt_engineering_production.md | others |
| Graph-based retrieval | graph_rag.md, vector_search_rag_architecture.md | others |

### qa_engineer
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Test strategy creation | property_based_testing.md, contract_testing.md, load_testing_methodology.md | others |
| Unit test focus | equivalence_partitioning.md, mutation_testing.md | others |
| API testing | contract_testing.md | others |
| Load/perf testing | load_testing_methodology.md | others |
| Exploratory testing | exploratory_testing_charters.md | others |

### security_engineer (DEVELOP pass — Gates S1, S2)
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| GATE S1 (package approval) | supply_chain_sbom_slsa.md, vulnerability_management_cve_patching.md | others |
| GATE S2 (feature review) | application_security_testing_sast_dast.md, api_security_owasp_top10.md, owasp_top10_review.md | others |
| Secrets management | secrets_management.md | others |
| Container security | container_kubernetes_security.md | others |
| AI/ML security | ai_ml_security_prompt_injection.md | others |
| Incident response | incident_response_runbook.md, forensics_log_analysis_dfir.md | others |
| DevSecOps pipeline | secure_sdlc_devsecops.md | others |

### devops_engineer
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| CI/CD pipeline setup | ci_cd_pipeline_design.md, twelve_factor_app.md | others |
| Deployment strategy | deployment_strategies.md | others |
| IaC/Terraform | iac_terraform_patterns.md | others |
| GitOps setup | gitops_argocd_flux.md | others |
| Platform engineering | platform_engineering_idp.md | others |

### sre_engineer
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| SLI/SLO definition | sli_slo_design.md, error_budget_policy.md | others |
| Observability setup | observability_three_pillars.md | others |
| Incident handling | incident_command_system.md, blameless_postmortem.md | others |
| Chaos testing | chaos_engineering.md | others |
| Toil reduction | toil_reduction.md | others |

### technical_writer
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| API documentation | api_reference_authoring.md, diataxis_framework.md | others |
| Changelog/release notes | changelog_release_notes.md | others |
| Onboarding docs | onboarding_documentation.md, plain_language.md | others |
| Developer handoff | developer_handoff_kit.md | others |
| Leadership deck | leadership_deck_authoring.md, audience_adaptation.md | others |
| Sales deck | sales_demo_deck.md, audience_adaptation.md | others |

### website_creator
| Activity | Load These Skills | Skip |
|----------|------------------|------|
| Landing page | landing_page_patterns.md, landing_page_copy.md, conversion_optimization.md, trust_signals_social_proof.md | others |
| SEO setup | seo_foundations.md, technical_seo_structured_data.md | others |
| Pricing page | pricing_page_design.md, conversion_psychology_principles.md | others |
| Analytics setup | analytics_event_tracking_setup.md, ab_testing_experimentation.md | others |
| Forms/lead capture | forms_lead_capture_ux.md, conversion_optimization.md | others |
| Content strategy | content_marketing_strategy.md, case_study_customer_stories.md | others |
| Responsive/mobile | responsive_design_mobile_first.md, image_video_optimization.md | others |
| i18n/multi-language | internationalization_seo_hreflang.md | others |
| Privacy/consent | cookie_consent_privacy_ux.md | others |
| Growth/referral | growth_loops_referral_plg.md, email_marketing_automation.md | others |

---

## USAGE RULES

1. **First activation of a role in a project:** Load the "Full" set (typically 3-5 core skills)
2. **Subsequent activations:** Load ONLY skills relevant to the specific task
3. **Gate activities:** Load ONLY gate-specific skills (e.g., S1 = supply_chain + vulnerability)
4. **If unsure which skills apply:** Load the role's top 3 by filename relevance to the task description
5. **Never load all 20 files** for security_engineer — pick the 2-3 that match the activity
6. **Token budget:** Max 3 skill files per role activation (exception: first-time full role activation during THINK/DESIGN = up to 5)

---

## SKILL LOADING PROTOCOL (for orchestrator to follow)

```
BEFORE activating any role:
1. Identify the ACTIVITY (not just the role)
2. Look up activity in this matrix
3. Load ONLY the listed skill files
4. If activity not listed → load top 2 files by filename match to task keywords
5. Read skill file → extract key principles → produce artifact
6. Do NOT keep full skill file content in context after extraction — summarize to 5-line takeaway
```

This protocol replaces the old "read ALL .md files in that folder" rule.
