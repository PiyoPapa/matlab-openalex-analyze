function cfg = env_check(cfg)
%TOPICMAP.ENV_CHECK  Validate environment and dependencies for openalex-topic-map.
%
%   cfg = topicmap.env_check(cfg)
%
% This function populates cfg.env.* and throws an error only for conditions
% that would make the *minimal* demo impossible to run.
%
% Minimal demo requirements:
%   - MATLAB base functionality (table, kmeans, pca)
%   - topic-map src path is already on path (caller responsibility)
%
% Optional / advanced features (warn if missing):
%   - pipeline repo present
%   - normalize repo present
%   - GPU availability
%   - UMAP implementation availability
%   - HDBSCAN implementation availability

    arguments
        cfg (1,1) struct
    end

    msgs = string.empty(0,1);
    warns = string.empty(0,1);

    % ---------- Basic cfg sanity ----------
    requiredFields = ["repoRoot","hubRoot","pipelineRoot","normalizeRoot","srcRoot","runsRoot","runId","runDir","seed"];
    missing = requiredFields(~isfield(cfg, requiredFields));
    if ~isempty(missing)
        error("topicmap:env:BadCfg", "cfg is missing required fields: %s", strjoin(missing, ", "));
    end

    % ---------- Repo presence checks (pipeline/normalize are assumed by design) ----------
    hasPipeline  = isfolder(cfg.pipelineRoot) && isfolder(fullfile(cfg.pipelineRoot,"src"));
    hasNormalize = isfolder(cfg.normalizeRoot) && isfolder(fullfile(cfg.normalizeRoot,"src"));

    if ~hasPipeline
        warns(end+1) = "Pipeline repo not found (expected src/). If you want end-to-end fetch, clone matlab-openalex-pipeline under hubRoot.";
    end
    if ~hasNormalize
        warns(end+1) = "Normalize repo not found (expected src/). If you want end-to-end normalization, clone matlab-openalex-normalize under hubRoot.";
    end

    % ---------- Minimal MATLAB function availability ----------
    % We treat missing as hard error because minimal demo relies on it.
    reqFcns = ["kmeans","pca","table","readtable","writetable"];
    missingFcns = string.empty(0,1);
    for f = reqFcns
        if exist(f, "file") == 0
            missingFcns(end+1) = f; %#ok<AGROW>
        end
    end
    if ~isempty(missingFcns)
        error("topicmap:env:MissingMATLAB", ...
            "Required MATLAB functions not found: %s. Your MATLAB installation/toolboxes may be incomplete.", ...
            strjoin(missingFcns, ", "));
    end

    % ---------- GPU availability (optional) ----------
    hasGPU = false;
    try
        % gpuDeviceCount exists in Parallel Computing Toolbox; if not, catch.
        if exist("gpuDeviceCount","file") ~= 0
            hasGPU = gpuDeviceCount("available") > 0;
        end
    catch
        hasGPU = false;
    end
    if ~hasGPU
        warns(end+1) = "GPU not detected (or Parallel Computing Toolbox not available). GPU-accelerated embedding may be unavailable; CPU mode should still work for small samples.";
    end

    % ---------- UMAP availability (optional) ----------
    % We cannot rely on a single canonical function name; check common ones.
    hasUMAP = has_any_function_(["run_umap","umap","UMAP"], ...
        ["UMAP function not found. Minimal demo can fall back to PCA, but UMAP-based maps will be unavailable unless you add an implementation to the MATLAB path."]);

    % ---------- HDBSCAN availability (optional) ----------
    hasHDBSCAN = has_any_function_(["hdbscan","HDBSCAN"], ...
        ["HDBSCAN function not found. This is optional; k-means remains the default clustering method."]);

    % ---------- Sample data presence (optional but recommended) ----------
    hasSampleWorks = false;
    hasSampleEmbed = false;
    if isfield(cfg,"sample") && isstruct(cfg.sample)
        if isfield(cfg.sample,"worksCsv") && strlength(string(cfg.sample.worksCsv))>0
            hasSampleWorks = isfile(cfg.sample.worksCsv);
            if ~hasSampleWorks
                warns(end+1) = "Sample worksCsv path is set but file does not exist. Minimal demo may fail unless you provide input data.";
            end
        else
            warns(end+1) = "cfg.sample.worksCsv is not set. Provide a small sample dataset for a guaranteed first-run experience.";
        end

        if isfield(cfg.sample,"embeddingMat") && strlength(string(cfg.sample.embeddingMat))>0
            hasSampleEmbed = isfile(cfg.sample.embeddingMat);
            if ~hasSampleEmbed
                warns(end+1) = "Sample embeddingMat path is set but file does not exist. Minimal demo may require computing embeddings, which can be slow without GPU.";
            end
        end
    else
        warns(end+1) = "cfg.sample is not configured. Consider shipping a small sample dataset (or embeddings) for the minimal demo.";
    end

    % ---------- Runs directory sanity ----------
    if ~isfolder(cfg.runDir)
        try
            mkdir(cfg.runDir);
            msgs(end+1) = "Created run directory: " + string(cfg.runDir);
        catch ME
            error("topicmap:env:RunDir", "Failed to create run directory: %s (%s)", cfg.runDir, ME.message);
        end
    end

    % ---------- Populate cfg.env ----------
    cfg.env = struct();
    cfg.env.okMinimal   = true;  % if we reached here, minimal requirements are satisfied
    cfg.env.hasPipeline = hasPipeline;
    cfg.env.hasNormalize = hasNormalize;
    cfg.env.hasGPU      = hasGPU;
    cfg.env.hasUMAP     = hasUMAP;
    cfg.env.hasHDBSCAN  = hasHDBSCAN;
    cfg.env.hasSampleWorks = hasSampleWorks;
    cfg.env.hasSampleEmbed = hasSampleEmbed;

    cfg.env.messages = msgs;
    cfg.env.warnings = warns;

    % Print warnings in a concise way (do not spam).
    if ~isempty(warns)
        fprintf("[topicmap.env_check] WARN (%d):\n", numel(warns));
        for i = 1:numel(warns)
            fprintf("  - %s\n", warns(i));
        end
    else
        fprintf("[topicmap.env_check] OK: environment looks good.\n");
    end

    % ---------- nested helper ----------
    function tf = has_any_function_(candidates, warnText)
        tf = false;
        for name = candidates
            if exist(name, "file") ~= 0
                tf = true;
                return;
            end
        end
        if strlength(string(warnText)) > 0
            warns(end+1) = string(warnText);
        end
    end
end
