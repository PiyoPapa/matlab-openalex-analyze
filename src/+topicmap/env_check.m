function cfg = env_check(cfg)
%TOPICMAP.ENV_CHECK  Validate environment and dependencies for matlab-openalex-analyze.
%
%   cfg = topicmap.env_check(cfg)
%
% This function populates cfg.env.* and throws an error only for conditions
% that would make the *minimal* chapter impossible to run.
%
% Side effects (intentional):
%   - creates cfg.baseOutDir if it does not exist (shared output root)
%
% Minimal chapter requirements:
%   - Statistics and Machine Learning Toolbox (PCA/k-means)
%   - basic MATLAB IO (table/readtable/writetable)
%
% Optional / advanced features (warn if missing, chapter-dependent):
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
    % New contract: env_check must NOT depend on run-specific fields
    requiredFields = ["repoRoot","hubRoot","pipelineRoot","normalizeRoot","srcRoot","baseOutDir","seed"];
    missing = requiredFields(~isfield(cfg, requiredFields));
    if ~isempty(missing)
        error("topicmap:env:BadCfg", "cfg is missing required fields: %s", strjoin(missing, ", "));
    end

    % Ensure baseOutDir exists (shared output root). This is an intentional side effect.
    if ~isfolder(cfg.baseOutDir)
        mkdir(cfg.baseOutDir);
    end

    % ---------- Repo presence checks (optional at this stage) ----------
    hasPipeline  = isfolder(cfg.pipelineRoot) && isfolder(fullfile(cfg.pipelineRoot,"src"));
    hasNormalize = isfolder(cfg.normalizeRoot) && isfolder(fullfile(cfg.normalizeRoot,"src"));

    if ~hasPipeline
        warns(end+1) = "Pipeline repo not found (expected <hub>/matlab-openalex-pipeline/src). End-to-end fetch will be unavailable.";
        recs(end+1)  = "Clone matlab-openalex-pipeline under hubRoot and re-run topicmap.env_check().";
    end
    if ~hasNormalize
        warns(end+1) = "Normalize repo not found (expected <hub>/matlab-openalex-normalize/src). This is OK for Chapter 02 (JSONL -> Map).";
        recs(end+1)  = "Optional: clone matlab-openalex-normalize only if you want CSV-based workflows.";
    end

    % ---------- Required toolboxes (minimal chapter) ----------
    % Your declared policy:
    %   Required: Statistics and Machine Learning Toolbox
    %   Optional: UMAP / HDBSCAN / BERT / GPU
    hasStatsML = license("test","Statistics_Toolbox") || license("test","Statistics_and_Machine_Learning_Toolbox");
    if ~hasStatsML
        error("topicmap:env:MissingStatsML", ...
            "Statistics and Machine Learning Toolbox is required (PCA/k-means).");
    end

    % ---------- Required MATLAB function availability ----------
    % Treat missing as hard error: minimal chapter relies on these.
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
        "UMAP function not found. Minimal chapter can fall back to PCA. " + ...
        "If you want UMAP-based maps, install a MATLAB UMAP add-on (recommended: Add-On Explorer -> 'Uniform Manifold Approximation and Projection (UMAP)' -> Add to MATLAB).");

    if ~hasUMAP
        if has_addon_like_("umap")
            warns(end+1) = "UMAP add-on may already be installed, but functions are not visible on the MATLAB path. Try restarting MATLAB, then re-run topicmap.env_check().";
        end
        recs(end+1) = "Optional: Install UMAP via Add-On Explorer (Add to MATLAB). After installation, restart MATLAB if functions are not detected.";
    end

    % ---------- 2D embedding availability (Chapter 03+) ----------
    hasTSNE = exist("tsne","file") ~= 0;
    if ~(hasUMAP || hasTSNE)
        warns(end+1) = "No 2D embedding method found (umap/run_umap/tsne). Chapter 03 requires a 2D layout method.";
        recs(end+1)  = "For Chapter 03: install a UMAP add-on (recommended) or ensure tsne() is available, then re-run topicmap.env_check().";
    end

    % ---------- HDBSCAN availability (optional) ----------
    hasHDBSCAN = has_any_function_(["hdbscan","HDBSCAN"], ...
        "HDBSCAN function not found. This is optional (k-means remains default). " + ...
        "If you want density-based clustering, install an HDBSCAN add-on (recommended: Add-On Explorer -> 'HDBSCAN' -> Add to MATLAB).");
    if ~hasHDBSCAN
        if has_addon_like_("hdbscan")
            warns(end+1) = "HDBSCAN add-on may already be installed, but functions are not visible on the MATLAB path. Try restarting MATLAB, then re-run topicmap.env_check().";
        end
        recs(end+1) = "Optional: Install HDBSCAN via Add-On Explorer (Add to MATLAB). After installation, restart MATLAB if functions are not detected.";
    end

    % ---------- BERT / Text Embedding availability ----------
    % NOTE: license("test", ...) is not always reliable across license setups.
    % For Ch_03 we use runtime checks instead.
    hasDL = license("test","Neural_Network_Toolbox") || license("test","Deep_Learning_Toolbox");

    % Ch_03 uses MATLAB standard documentEmbedding + embed.
    hasDocEmb = exist("documentEmbedding","file") ~= 0;
    hasMiniLM_L6 = false;
    hasMiniLM_L12 = false;
    hasTextEmbed = false;     % interpret as "MiniLM embedding stack usable"
    hasEmbedOk = false;

    if ~hasDocEmb
        recs(end+1) = "For Chapter 03: documentEmbedding not found. Install Text Analytics Toolbox and restart MATLAB.";
    else
        % Detect via Add-On Identifiers (most robust)
        try
            addons = matlab.addons.installedAddons;
            ids = string(addons.Identifier);
            hasMiniLM_L6  = any(ids == "MINILML6V2");
            hasMiniLM_L12 = any(ids == "MINILML12V2");
        catch
            % If installedAddons is unavailable for any reason, fall back to runtime check below
        end

        % Runtime truth: can we construct the embedding model?
        try
            embL6 = documentEmbedding(Model="all-MiniLM-L6-v2"); %#ok<NASGU>
            hasMiniLM_L6 = true;
        catch
            hasMiniLM_L6 = false;
        end
        try
            embL12 = documentEmbedding(Model="all-MiniLM-L12-v2"); %#ok<NASGU>
            hasMiniLM_L12 = true;
        catch
            hasMiniLM_L12 = false;
        end

        % Runtime truth: can we embed a short string?
        if hasMiniLM_L6
            try
                emb = documentEmbedding(Model="all-MiniLM-L6-v2");
                v = embed(emb, "hello"); %#ok<NASGU>
                hasEmbedOk = true;
            catch
                hasEmbedOk = false;
            end
        end
        hasTextEmbed = hasMiniLM_L6 && hasEmbedOk;
        if ~hasMiniLM_L6
            warns(end+1) = "MiniLM support package missing: all-MiniLM-L6-v2 (required for Chapter 03 standard embeddings).";
            recs(end+1)  = "For Chapter 03: install 'Text Analytics Toolbox Model for all-MiniLM-L6-v2 Network', then re-run topicmap.env_check().";
        end
        if ~hasMiniLM_L12
            recs(end+1)  = "Optional: Install 'Text Analytics Toolbox Model for all-MiniLM-L12-v2 Network' if you want the larger variant.";
        end
    end
    % Keep legacy BERT flag (still optional/future)
    hasBERT = false;
    if hasDL
        hasBERT = exist("bert","file") ~= 0;
    end
    if ~hasDL
        recs(end+1) = "Optional: Deep Learning Toolbox is needed for GPU-heavy workflows (future chapters).";
    end

    % ---------- Detect availability of a standard JSONL (one work per line) ----
    % NOTE: cfg.runDir is optional here; chapters create it explicitly.
    % Ch_02 gate: we only need at least one *.standard.jsonl reachable.
    hasPipelineJsonl = false;
    try
        if isfolder(fullfile(cfg.repoRoot, "data_sample"))
            d = dir(fullfile(cfg.repoRoot, "data_sample", "*.standard.jsonl"));
            hasPipelineJsonl = ~isempty(d);
        end
        % runDir may not exist yet (chapter responsibility)
        if ~hasPipelineJsonl && isfield(cfg,"runDir") && isfolder(cfg.runDir)
            d = dir(fullfile(cfg.runDir, "*.standard.jsonl"));
            hasPipelineJsonl = ~isempty(d);
        end
    catch
        hasPipelineJsonl = false;
    end

    % ---- Explicit pipeline JSONL path (user-provided) ----
    % IMPORTANT: define this BEFORE any logic references it (short-circuit bugs otherwise).
    hasPipelineJsonlPath = false;
    if isfield(cfg,"input") && isstruct(cfg.input) && isfield(cfg.input,"pipelineJsonl")
        pj = string(cfg.input.pipelineJsonl);
        if strlength(pj) > 0
            hasPipelineJsonlPath = isfile(pj);
        end
    end

    % ---------- Sample data presence (optional but recommended) ----------
    hasSampleWorks = false;
    hasSampleEmbed = false;
    if isfield(cfg,"sample") && isstruct(cfg.sample)
        hasWorksCsv = isfield(cfg.sample,"worksCsv") && strlength(string(cfg.sample.worksCsv))>0 && isfile(cfg.sample.worksCsv);
        hasWorksJsonl = isfield(cfg.sample,"worksJsonl") && strlength(string(cfg.sample.worksJsonl))>0 && isfile(cfg.sample.worksJsonl);
        hasSampleWorks = hasWorksCsv || hasWorksJsonl;
        if isfield(cfg.sample,"worksCsv") && strlength(string(cfg.sample.worksCsv))>0 && ~hasWorksCsv

            if ~hasSampleWorks
                warns(end+1) = "Sample worksCsv path is set but file does not exist. Minimal chapter may fail unless you provide input data.";
                recs(end+1)  = "Provide cfg.sample.worksCsv (e.g., data_sample/works_sample.csv) or generate one from pipeline/normalize outputs.";
            end
        elseif ~hasSampleWorks
            % If Ch_02 (JSONL -> text) is available, worksCsv is not required.
            if ~(hasPipelineJsonl || hasPipelineJsonlPath)
                warns(end+1) = "No input data configured: cfg.sample.worksCsv is not set and no pipeline JSONL is available. Provide at least one to run chapters.";
            end
            recs(end+1)  = "Optional: set cfg.sample.worksJsonl (recommended) or cfg.sample.worksCsv to support the minimal chapter (Ch_01).";     
        end

        if isfield(cfg.sample,"embeddingMat") && strlength(string(cfg.sample.embeddingMat))>0
            hasSampleEmbed = isfile(cfg.sample.embeddingMat);
            if ~hasSampleEmbed
                warns(end+1) = "Sample embeddingMat path is set but file does not exist. Minimal chapter may require computing embeddings, which can be slow without GPU.";
                recs(end+1)  = "Provide cfg.sample.embeddingMat (e.g., data_sample/embeddings_sample.mat) to run Ch_01 without BERT/GPU.";
            end
        end
    else
        warns(end+1) = "cfg.sample is not configured. Consider shipping a small sample dataset (or embeddings) for the minimal chapter.";
        recs(end+1)  = "Add cfg.sample.* defaults in topicmap.setup() and ship minimal files under data_sample/.";
    end

    % ---------- Pipeline JSONL input hint (for Ch_02) ----------
    % (Keep separate info: explicit user-provided path)
    if isfield(cfg,"input") && isstruct(cfg.input) && isfield(cfg.input,"pipelineJsonl")
        pj = string(cfg.input.pipelineJsonl);
        if strlength(pj) > 0
            if ~hasPipelineJsonlPath
                warns(end+1) = "cfg.input.pipelineJsonl is set but file does not exist. Ch_02 will fail until you point to a pipeline JSONL.";
                recs(end+1)  = "Set cfg.input.pipelineJsonl to a pipeline output JSONL (works JSONL).";
            end
        else
            recs(end+1) = "For Chapter 02: set cfg.input.pipelineJsonl to a pipeline output JSONL (works JSONL).";
        end
    else
        recs(end+1) = "For Chapter 02: add cfg.input.pipelineJsonl in topicmap.setup() (already supported) and set it to a pipeline JSONL.";
    end

    % ---------- Populate cfg.env ----------
    cfg.env = struct();
    % Doctor-style summary
    cfg.env.requiredOk  = true;  % if we reached here, required checks passed
    cfg.env.okMinimal   = true;  % backward-compatible flag

    cfg.env.hasStatsML  = hasStatsML;
    cfg.env.hasPipeline = hasPipeline;
    cfg.env.hasNormalize = hasNormalize;

    cfg.env.hasGPU      = hasGPU;
    cfg.env.hasUMAP     = hasUMAP;
    cfg.env.hasTSNE     = hasTSNE;
    cfg.env.hasHDBSCAN  = hasHDBSCAN;
    cfg.env.hasDL       = hasDL;
    cfg.env.hasTextEmbed = hasTextEmbed;
    cfg.env.hasBERT     = hasBERT;
    cfg.env.hasDocEmb   = hasDocEmb;
    cfg.env.hasMiniLM_L6  = hasMiniLM_L6;
    cfg.env.hasMiniLM_L12 = hasMiniLM_L12;
    cfg.env.hasPipelineJsonl = hasPipelineJsonl;
    cfg.env.hasPipelineJsonlPath = hasPipelineJsonlPath;

    cfg.env.hasSampleWorks = hasSampleWorks;
    cfg.env.hasSampleEmbed = hasSampleEmbed;

    cfg.env.messages = msgs;
    cfg.env.warnings = warns;
    cfg.env.recommendations = unique(recs, 'stable');

    % optionalOk (legacy): Ch_01 "recommended experience"
    % Prefer concrete readiness (sample embeddings OR MiniLM embedding stack), not "bert" (future/optional).
    cfg.env.optionalOk = cfg.env.hasSampleWorks && (cfg.env.hasSampleEmbed || cfg.env.hasTextEmbed);
    % new: optional readiness by chapter (canonical fields)
    cfg.env.optionalOk_Ch01 = cfg.env.optionalOk;
    % Ch_02: JSONL -> text baseline is doable without embeddings
    cfg.env.optionalOk_Ch02 = cfg.env.hasPipelineJsonl || cfg.env.hasPipelineJsonlPath;
    % Ch_03: standard embeddings require documentEmbedding + usable MiniLM embedding stack
    cfg.env.optionalOk_Ch03 = cfg.env.hasDocEmb && cfg.env.hasTextEmbed;
    % Ch_04: optional (depends on HDBSCAN availability)
    % Note: Ch_04 can be designed to run without HDBSCAN in the future,
    % but the current demo_04 expects HDBSCAN.
    cfg.env.optionalOk_Ch04 = cfg.env.hasHDBSCAN;
    % Ch_05: must run even if HDBSCAN is missing (k-means fallback),
    % but it needs at least one 2D layout method for the parallel view.
    cfg.env.optionalOk_Ch05 = cfg.env.hasStatsML && (cfg.env.hasUMAP || cfg.env.hasTSNE);

    % backward compatibility (legacy field names)
    cfg.env.optionalOk_demo01 = cfg.env.optionalOk_Ch01;
    cfg.env.optionalOk_demo02 = cfg.env.optionalOk_Ch02;
    cfg.env.optionalOk_demo03 = cfg.env.optionalOk_Ch03;
    cfg.env.optionalOk_demo04 = cfg.env.optionalOk_Ch04;
    cfg.env.optionalOk_demo05 = cfg.env.optionalOk_Ch05;
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
        fprintf("[topicmap.env_check] OK: required checks passed.\n");
        fprintf("  Chapter 01 ready: %d\n", cfg.env.optionalOk_Ch01);
        fprintf("  Chapter 02 ready: %d\n", cfg.env.optionalOk_Ch02);
        fprintf("  Chapter 03 ready: %d\n", cfg.env.optionalOk_Ch03);
        fprintf("  Chapter 04 ready: %d\n", cfg.env.optionalOk_Ch04);
        fprintf("  Chapter 05 ready: %d\n", cfg.env.optionalOk_Ch05);
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