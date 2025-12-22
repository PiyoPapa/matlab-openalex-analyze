function cfg = env_check(cfg)
%TOPICMAP.ENV_CHECK  Validate environment and dependencies for openalex-topic-map.
%
%   cfg = topicmap.env_check(cfg)
%
% This function populates cfg.env.* and throws an error only for conditions
% that would make the *minimal* demo impossible to run.
%
% Minimal demo requirements:
%   - Statistics and Machine Learning Toolbox (PCA/k-means)
%   - basic MATLAB IO (table/readtable/writetable)
%
% Optional / advanced features (warn if missing):
%   - GPU availability
%   - UMAP implementation availability
%   - HDBSCAN implementation availability
%   - BERT / Text Analytics + Deep Learning toolbox availability (future)
 
    arguments
        cfg (1,1) struct
    end

    msgs  = string.empty(0,1);
    warns = string.empty(0,1);
    recs  = string.empty(0,1);

    % ---------- Basic cfg sanity ----------
    requiredFields = ["repoRoot","hubRoot","pipelineRoot","normalizeRoot","srcRoot","runsRoot","runId","runDir","seed"];
    missing = requiredFields(~isfield(cfg, requiredFields));
    if ~isempty(missing)
        error("topicmap:env:BadCfg", "cfg is missing required fields: %s", strjoin(missing, ", "));
    end

    % ---------- Repo presence checks (optional at this stage) ----------
    hasPipeline  = isfolder(cfg.pipelineRoot) && isfolder(fullfile(cfg.pipelineRoot,"src"));
    hasNormalize = isfolder(cfg.normalizeRoot) && isfolder(fullfile(cfg.normalizeRoot,"src"));

    if ~hasPipeline
        warns(end+1) = "Pipeline repo not found (expected <hub>/matlab-openalex-pipeline/src). End-to-end fetch will be unavailable.";
        recs(end+1)  = "Clone matlab-openalex-pipeline under hubRoot and re-run topicmap.env_check().";
    end
    if ~hasNormalize
        warns(end+1) = "Normalize repo not found (expected <hub>/matlab-openalex-normalize/src). This is OK for demo_02 (JSONL->map).";
        recs(end+1)  = "Optional: clone matlab-openalex-normalize only if you want CSV-based workflows.";
    end

    % ---------- Required toolboxes (minimal demo) ----------
    % Your declared policy:
    %   Required: Statistics and Machine Learning Toolbox
    %   Optional: UMAP / HDBSCAN / BERT / GPU
    hasStatsML = license("test","Statistics_Toolbox") || license("test","Statistics_and_Machine_Learning_Toolbox");
    if ~hasStatsML
        error("topicmap:env:MissingStatsML", ...
            "Statistics and Machine Learning Toolbox is required (PCA/k-means).");
    end

    % ---------- Required MATLAB function availability ----------
    % Treat missing as hard error: minimal demo relies on these.
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
        recs(end+1)  = "If you plan to compute embeddings locally, use GPU + Deep Learning Toolbox when available (optional).";
    end

    % ---------- UMAP availability (optional) ----------
    % We cannot rely on a single canonical function name; check common ones.
    hasUMAP = has_any_function_(["run_umap","umap","UMAP"], ...
        ["UMAP function not found. Minimal demo can fall back to PCA. " + ...
         "If you want UMAP-based maps, install a MATLAB UMAP add-on (recommended: Add-On Explorer -> 'Uniform Manifold Approximation and Projection (UMAP)' -> Add to MATLAB)."]);
    if ~hasUMAP
        if has_addon_like_("umap")
            warns(end+1) = "UMAP add-on may already be installed, but functions are not visible on the MATLAB path. Try restarting MATLAB, then re-run topicmap.env_check().";
        end
        recs(end+1) = "Optional: Install UMAP via Add-On Explorer (Add to MATLAB). After installation, restart MATLAB if functions are not detected.";
    end

    % ---------- HDBSCAN availability (optional) ----------
    hasHDBSCAN = has_any_function_(["hdbscan","HDBSCAN"], ...
        ["HDBSCAN function not found. This is optional (k-means remains default). " + ...
         "If you want density-based clustering, install an HDBSCAN add-on (recommended: Add-On Explorer -> 'HDBSCAN' -> Add to MATLAB)."]);
    if ~hasHDBSCAN
        if has_addon_like_("hdbscan")
            warns(end+1) = "HDBSCAN add-on may already be installed, but functions are not visible on the MATLAB path. Try restarting MATLAB, then re-run topicmap.env_check().";
        end
        recs(end+1) = "Optional: Install HDBSCAN via Add-On Explorer (Add to MATLAB). After installation, restart MATLAB if functions are not detected.";
    end

    % ---------- BERT availability (optional; future) ----------
    % We only detect broad prerequisites here; actual model availability is handled later.
    hasDL = license("test","Neural_Network_Toolbox") || license("test","Deep_Learning_Toolbox");
    hasText = license("test","Text_Analytics_Toolbox");
    hasBERT = false;
    if hasDL && hasText
        % Some distributions provide 'bert' as a function; not guaranteed.
        hasBERT = exist("bert","file") ~= 0;
    end
    if ~(hasDL && hasText)
        recs(end+1) = "Optional: Deep Learning Toolbox + Text Analytics Toolbox are needed for BERT-based embeddings.";
    end

    % ---------- Sample data presence (optional but recommended) ----------
    hasSampleWorks = false;
    hasSampleEmbed = false;
    if isfield(cfg,"sample") && isstruct(cfg.sample)
        if isfield(cfg.sample,"worksCsv") && strlength(string(cfg.sample.worksCsv))>0
            hasSampleWorks = isfile(cfg.sample.worksCsv);
            if ~hasSampleWorks
                warns(end+1) = "Sample worksCsv path is set but file does not exist. Minimal demo may fail unless you provide input data.";
                recs(end+1)  = "Provide cfg.sample.worksCsv (e.g., data_sample/works_sample.csv) or generate one from pipeline/normalize outputs.";
            end
        else
            warns(end+1) = "cfg.sample.worksCsv is not set. Provide a small sample dataset for a guaranteed first-run experience.";
            recs(end+1)  = "Set cfg.sample.worksCsv in topicmap.setup() (recommended) or pass your own data path.";
        end

        if isfield(cfg.sample,"embeddingMat") && strlength(string(cfg.sample.embeddingMat))>0
            hasSampleEmbed = isfile(cfg.sample.embeddingMat);
            if ~hasSampleEmbed
                warns(end+1) = "Sample embeddingMat path is set but file does not exist. Minimal demo may require computing embeddings, which can be slow without GPU.";
                recs(end+1)  = "Provide cfg.sample.embeddingMat (e.g., data_sample/embeddings_sample.mat) to run demo_01 without BERT/GPU.";
            end
        end
    else
        warns(end+1) = "cfg.sample is not configured. Consider shipping a small sample dataset (or embeddings) for the minimal demo.";
        recs(end+1)  = "Add cfg.sample.* defaults in topicmap.setup() and ship minimal files under data_sample/.";
    end

    % ---------- Pipeline JSONL input hint (for demo_02) ----------
    hasPipelineJsonl = false;
    if isfield(cfg,"input") && isstruct(cfg.input) && isfield(cfg.input,"pipelineJsonl")
        pj = string(cfg.input.pipelineJsonl);
        if strlength(pj) > 0
            hasPipelineJsonl = isfile(pj);
            if ~hasPipelineJsonl
                warns(end+1) = "cfg.input.pipelineJsonl is set but file does not exist. demo_02 will fail until you point to a pipeline JSONL.";
                recs(end+1)  = "Set cfg.input.pipelineJsonl to a pipeline output JSONL (works JSONL).";
            end
        else
            recs(end+1) = "For demo_02: set cfg.input.pipelineJsonl to a pipeline output JSONL (works JSONL).";
        end
    else
        recs(end+1) = "For demo_02: add cfg.input.pipelineJsonl in topicmap.setup() (already supported) and set it to a pipeline JSONL.";
    end

    % ---------- Populate cfg.env ----------
    cfg.env = struct();
    % Doctor-style summary
    cfg.env.requiredOk  = true;  % if we reached here, required checks passed
    cfg.env.optionalOk  = true;  % may be flipped below
    cfg.env.okMinimal   = true;  % backward-compatible flag

    cfg.env.hasStatsML  = hasStatsML;
    cfg.env.hasPipeline = hasPipeline;
    cfg.env.hasNormalize = hasNormalize;

    cfg.env.hasGPU      = hasGPU;
    cfg.env.hasUMAP     = hasUMAP;
    cfg.env.hasHDBSCAN  = hasHDBSCAN;
    cfg.env.hasDL       = hasDL;
    cfg.env.hasText     = hasText;
    cfg.env.hasBERT     = hasBERT;

    cfg.env.hasSampleWorks = hasSampleWorks;
    cfg.env.hasSampleEmbed = hasSampleEmbed;

    cfg.env.messages = msgs;
    cfg.env.warnings = warns;
    cfg.env.recommendations = unique(recs);

    % optionalOk (legacy): keep behavior for demo_01 "recommended experience"
    cfg.env.optionalOk = cfg.env.hasSampleWorks && (cfg.env.hasSampleEmbed || cfg.env.hasBERT);
    % new: optional readiness by demo
    cfg.env.optionalOk_demo01 = cfg.env.optionalOk;
    cfg.env.optionalOk_demo02 = cfg.env.hasPipelineJsonl && cfg.env.hasBERT;

    % Print warnings in a concise way (do not spam).
    if ~isempty(warns)
        fprintf("[topicmap.env_check] WARN (%d):\n", numel(warns));
        for i = 1:numel(warns)
            fprintf("  - %s\n", warns(i));
        end
        if ~isempty(cfg.env.recommendations)
            fprintf("[topicmap.env_check] NEXT (%d):\n", numel(cfg.env.recommendations));
            for i = 1:numel(cfg.env.recommendations)
                fprintf("  * %s\n", cfg.env.recommendations(i));
            end
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

function tf = has_addon_like_(needle)
% Return true if an installed Add-On appears to match the keyword.
tf = false;
try
    if exist("matlab.addons.installedAddons","file") == 0
        return;
    end
    A = matlab.addons.installedAddons();
    if isempty(A)
        return;
    end
    names = lower(string(A.Name));
    tf = any(contains(names, lower(string(needle))));
catch
    tf = false;
end
end