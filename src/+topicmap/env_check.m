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
    % Mode is optional. This repo can run Ch_00–05 with a resolved *.standard.jsonl.
    mode = "standalone";
    if isfield(cfg,"input") && isstruct(cfg.input) && isfield(cfg.input,"mode")
        mode = lower(strtrim(string(cfg.input.mode)));
        if mode == "" || mode == "auto", mode = "standalone"; end
    end

    % Ensure baseOutDir exists (shared output root). This is an intentional side effect.
    if ~isfolder(cfg.baseOutDir)
        mkdir(cfg.baseOutDir);
    end

    % ---------- Ensure runDir exists (stable output location per run) ----------
    % Policy:
    %   - runDir is required for reproducible outputs/logs.
    %   - If cfg.runDir is missing/empty, create a timestamped folder under baseOutDir/runs/.
    %   - If cfg.runDir is provided but does not exist, create it.
    runDirCreated = false;
    if ~isfield(cfg,"runDir") || strlength(string(cfg.runDir))==0
        ts = string(datetime("now","Format","yyyyMMdd_HHmmss"));
        cfg.runDir = char(fullfile(cfg.baseOutDir, "runs", ts));
        runDirCreated = true;
    end
    if ~isfolder(cfg.runDir)
        mkdir(cfg.runDir);
        runDirCreated = true;
    end
    % Optional: record in env for transparency
    % (cfg.env is created later; store temp flag)
    tmp_runDirCreated = runDirCreated;

    % ---------- Repo presence checks (mode-aware) ----------
    % "expected" roots are always derived; "detected" indicates repo exists and is usable.
    % Policy:
    % - Prefer explicit cfg.pipelineRoot / cfg.normalizeRoot when they point to existing repos.
    % - Otherwise, derive under hubRoot (hubRoot is the intended parent folder for peer repos).
    hubRoot = string(cfg.hubRoot);
    expectedPipelineRoot  = string(cfg.pipelineRoot);
    expectedNormalizeRoot = string(cfg.normalizeRoot);

    if (strlength(expectedPipelineRoot)==0 || ~isfolder(expectedPipelineRoot)) && strlength(hubRoot)>0
        expectedPipelineRoot = fullfile(hubRoot, "matlab-openalex-pipeline");
    end
    if (strlength(expectedNormalizeRoot)==0 || ~isfolder(expectedNormalizeRoot)) && strlength(hubRoot)>0
        expectedNormalizeRoot = fullfile(hubRoot, "matlab-openalex-normalize");
    end
    expectedPipelineSrc   = fullfile(expectedPipelineRoot,"src");
    expectedNormalizeSrc  = fullfile(expectedNormalizeRoot,"src");
    hasPipeline  = isfolder(expectedPipelineRoot)  && isfolder(expectedPipelineSrc);
    hasNormalize = isfolder(expectedNormalizeRoot) && isfolder(expectedNormalizeSrc);

    % Policy:
    % - Ch_00 is explicitly a diagnostics chapter; missing peer repos are INFO (optional).
    % - Mode=full still enforces pipeline repo presence as a hard error.
    if mode == "full" && ~hasPipeline
        error("topicmap:env:MissingPipelineRepo", ...
            "Mode=full requires pipeline repo under hubRoot. Expected: %s", string(expectedPipelineSrc));
    end
    if ~hasPipeline
        msgs(end+1) = "Pipeline repo not found (expected " + string(expectedPipelineSrc) + "). End-to-end fetch is optional.";
        recs(end+1) = "Optional: clone matlab-openalex-pipeline under hubRoot if you want to fetch your own JSONL.";
    end
    if ~hasNormalize
        msgs(end+1) = "Normalize repo not found (expected " + string(expectedNormalizeSrc) + "). Normalize step is optional.";
        recs(end+1) = "Optional: clone matlab-openalex-normalize if you want CSV-based workflows.";
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
    % Ch_02 gate: we only need at least one *.standard.jsonl reachable.
    resolvedStandardJsonl = "";
    try
        if isfolder(fullfile(cfg.repoRoot, "data_sample"))
            d = dir(fullfile(cfg.repoRoot, "data_sample", "*.standard.jsonl"));
            if ~isempty(d)
                resolvedStandardJsonl = string(fullfile(d(1).folder, d(1).name));
            end
        end
        % runDir may not exist yet (chapter responsibility)
        if strlength(resolvedStandardJsonl)==0 && isfield(cfg,"runDir") && isfolder(cfg.runDir)
            d = dir(fullfile(cfg.runDir, "*.standard.jsonl"));
            if ~isempty(d)
                resolvedStandardJsonl = string(fullfile(d(1).folder, d(1).name));
            end
        end
    catch
        resolvedStandardJsonl = "";
    end

    % ---- Explicit pipeline JSONL path (user-provided) ----
    % IMPORTANT: define this BEFORE any logic references it (short-circuit bugs otherwise).
    hasPipelineJsonlPath = false;
    if isfield(cfg,"input") && isstruct(cfg.input) && isfield(cfg.input,"pipelineJsonl")
        pj = string(cfg.input.pipelineJsonl);
        if strlength(pj) > 0
            hasPipelineJsonlPath = isfile(pj);
            if hasPipelineJsonlPath
                resolvedStandardJsonl = pj; % explicit path wins
            end
        end
    end
    hasAnyJsonl = strlength(resolvedStandardJsonl) > 0;
    % Backward-compat shim (do not use legacy variables anywhere else)
    % NOTE: legacy "hasPipelineJsonl" used to mean "bundled jsonl exists".
    hasBundledStandardJsonl = false;
    if strlength(resolvedStandardJsonl) > 0
        % Treat data_sample/*.standard.jsonl as "bundled" JSONL
        hasBundledStandardJsonl = contains(resolvedStandardJsonl, fullfile(cfg.repoRoot,"data_sample"));
    end

    % ---------- Sample data presence (optional but recommended) ----------
    % Policy for this repo:
    %   "sample input" can be provided either as worksCsv/worksJsonl OR as bundled *.standard.jsonl under data_sample/.
    hasSampleWorks = false;
    hasSampleEmbed = false;
    if isfield(cfg,"sample") && isstruct(cfg.sample)
        hasWorksCsv = isfield(cfg.sample,"worksCsv") && strlength(string(cfg.sample.worksCsv))>0 && isfile(cfg.sample.worksCsv);
        hasWorksJsonl = isfield(cfg.sample,"worksJsonl") && strlength(string(cfg.sample.worksJsonl))>0 && isfile(cfg.sample.worksJsonl);
        hasSampleWorks = hasWorksCsv || hasWorksJsonl || hasBundledStandardJsonl;
        if isfield(cfg.sample,"worksCsv") && strlength(string(cfg.sample.worksCsv))>0 && ~hasWorksCsv

            if ~hasSampleWorks
                warns(end+1) = "Sample worksCsv path is set but file does not exist. Minimal chapter may fail unless you provide input data.";
                recs(end+1)  = "Provide cfg.sample.worksCsv (e.g., data_sample/works_sample.csv) or generate one from pipeline/normalize outputs.";
            end
        elseif ~hasSampleWorks
            % If Ch_02 (JSONL -> text) is available, worksCsv is not required.
            if ~hasAnyJsonl
                warns(end+1) = "No input data configured: no bundled *.standard.jsonl, no cfg.sample works file, and no pipeline JSONL path. Provide at least one to run chapters.";
            end
            recs(end+1)  = "Optional: place a small *.standard.jsonl under data_sample/ (recommended) or set cfg.sample.worksJsonl / cfg.sample.worksCsv.";     
        end

        if isfield(cfg.sample,"embeddingMat") && strlength(string(cfg.sample.embeddingMat))>0
            hasSampleEmbed = isfile(cfg.sample.embeddingMat);
            if ~hasSampleEmbed
                warns(end+1) = "Sample embeddingMat path is set but file does not exist. Minimal chapter may require computing embeddings, which can be slow without GPU.";
                recs(end+1)  = "Provide cfg.sample.embeddingMat (e.g., data_sample/embeddings_sample.mat) to run Ch_01 without BERT/GPU.";
            end
        end
    else
        % cfg.sample is OPTIONAL except when mode=sample
        if mode == "sample"
            warns(end+1) = "Mode=sample but cfg.sample is not configured. Provide cfg.sample.* or use data_sample/*.standard.jsonl.";
            recs(end+1)  = "Call topicmap.setup() to populate cfg.sample defaults, or set cfg.sample.* explicitly.";
        else
            msgs(end+1)  = "cfg.sample is not configured (optional for mode=" + mode + ").";
        end
    end

    % ---------- Input data gating (mode-aware) ----------
    % sample     : require sample worksJsonl (or worksCsv). pipelineJsonl is optional.
    % standalone : require cfg.input.pipelineJsonl (or a *.standard.jsonl in runDir)
    % full       : pipeline repo required; pipelineJsonl still recommended to be explicit.

    if mode == "sample"
        if ~env_guard_hasSampleInput_(cfg)
            warns(end+1) = "Mode=sample but no sample works file found. Provide data_sample/*.standard.jsonl or set cfg.sample.worksJsonl.";
            recs(end+1)  = "Place a small *.standard.jsonl under data_sample/ (recommended) or set cfg.sample.worksJsonl to an existing file.";
        end
    elseif mode == "standalone"
        if ~hasAnyJsonl
            warns(end+1) = "Mode=standalone but no *.standard.jsonl found. Chapter 02 will not run until you provide one.";
            recs(end+1)  = "Place a *.standard.jsonl under data_sample/ OR set cfg.input.pipelineJsonl to an existing file.";
        end
    elseif mode == "full"
        % pipeline repo presence already enforced above
        if ~hasAnyJsonl
            msgs(end+1) = "Mode=full is active. You can fetch via pipeline repo, but Chapter 02 still needs a pipeline JSONL path or a generated file in runDir.";
            recs(end+1) = "After fetching, set cfg.input.pipelineJsonl (recommended) or copy the generated *.standard.jsonl into runDir.";
        end
    else
        warns(end+1) = "Unknown cfg.input.mode: " + mode + ". Expected: sample|standalone|full.";
        recs(end+1)  = "Set cfg.input.mode to ""sample"", ""standalone"", or ""full"" in topicmap.setup().";
    end

    % ---------- Pipeline JSONL input hint (for Ch_02) ----------
    % Only recommend cfg.input.pipelineJsonl when we cannot resolve any *.standard.jsonl.
    if ~hasAnyJsonl
        recs(end+1) = "For Chapter 02: provide a *.standard.jsonl under data_sample/ OR set cfg.input.pipelineJsonl to an existing file.";
    else
        % If user set pipelineJsonl but it's broken, still warn.
        if isfield(cfg,"input") && isstruct(cfg.input) && isfield(cfg.input,"pipelineJsonl")
            pj = string(cfg.input.pipelineJsonl);
            if strlength(pj) > 0 && ~hasPipelineJsonlPath
                warns(end+1) = "cfg.input.pipelineJsonl is set but file does not exist. It will be ignored; using resolved standardJsonlPath instead.";
            end
        end
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
    cfg.env.hasBundledStandardJsonl = hasBundledStandardJsonl;
    cfg.env.hasPipelineJsonlPath = hasPipelineJsonlPath;
    cfg.env.standardJsonlPath = resolvedStandardJsonl;
    cfg.env.hasSampleWorks = hasSampleWorks;
    cfg.env.hasSampleEmbed = hasSampleEmbed;
    cfg.env.messages = msgs;
    cfg.env.warnings = warns;
    cfg.env.recommendations = unique(recs, 'stable');
    cfg.env.mode = mode;
    cfg.env.expectedPipelineRoot  = expectedPipelineRoot;
    cfg.env.expectedNormalizeRoot = expectedNormalizeRoot;
    cfg.env.runDir = string(cfg.runDir);
    cfg.env.runDirCreated = tmp_runDirCreated;

    % optionalOk (legacy): treat as Chapter 01 readiness.
    % Policy: "jsonl-bundled operation" should work even without sample CSV.
    % Ch_01 readiness is satisfied if any JSONL input exists (bundled or user-provided),
    % OR if legacy sample works (CSV/worksJsonl) exists.
    cfg.env.optionalOk_Ch01 = strlength(cfg.env.standardJsonlPath)>0 || cfg.env.hasSampleWorks;
    cfg.env.optionalOk = cfg.env.optionalOk_Ch01;
    % Ch_02: JSONL -> text baseline is doable without embeddings
    cfg.env.optionalOk_Ch02 = strlength(cfg.env.standardJsonlPath)>0;
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
    % Print summary (always show chapter readiness; warnings are additive)
    fprintf("[topicmap.env_check] OK: required checks passed. (mode=%s)\n", cfg.env.mode);
    fprintf("  Chapter 01 ready: %d\n", cfg.env.optionalOk_Ch01);
    fprintf("  Chapter 02 ready: %d\n", cfg.env.optionalOk_Ch02);
    fprintf("  Chapter 03 ready: %d\n", cfg.env.optionalOk_Ch03);
    fprintf("  Chapter 04 ready: %d\n", cfg.env.optionalOk_Ch04);
    fprintf("  Chapter 05 ready: %d\n", cfg.env.optionalOk_Ch05);
    fprintf("  runDir: %s\n", string(cfg.runDir));
    if cfg.env.runDirCreated, fprintf("  (runDir created)\n"); end
    if ~isempty(msgs)
        fprintf("[topicmap.env_check] INFO (%d):\n", numel(msgs));
        for i = 1:numel(msgs)
            fprintf("  - %s\n", msgs(i));
        end
    end
    if ~isempty(warns)
        fprintf("[topicmap.env_check] WARN (%d):\n", numel(warns));
        for i = 1:numel(warns)
            fprintf("  - %s\n", warns(i));
        end
    end
    if ~isempty(cfg.env.recommendations)
        fprintf("[topicmap.env_check] NEXT (%d):\n", numel(cfg.env.recommendations));
        for i = 1:numel(cfg.env.recommendations)
            fprintf("  * %s\n", cfg.env.recommendations(i));
        end
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

function tf = env_guard_hasSampleInput_(cfg)
% True if sample input is available for "sample" mode.
% Accepts:
%   - cfg.sample.worksCsv / cfg.sample.worksJsonl
%   - repoRoot/data_sample/*.standard.jsonl
tf = false;
try
    hasWorksCsv = false;
    hasWorksJsonl = false;
    if isfield(cfg,"sample") && isstruct(cfg.sample)
        hasWorksCsv = isfield(cfg.sample,"worksCsv") && strlength(string(cfg.sample.worksCsv))>0 && isfile(cfg.sample.worksCsv);
        hasWorksJsonl = isfield(cfg.sample,"worksJsonl") && strlength(string(cfg.sample.worksJsonl))>0 && isfile(cfg.sample.worksJsonl);
    end
    hasStandardJsonl = false;
    if isfield(cfg,"repoRoot") && isfolder(fullfile(cfg.repoRoot,"data_sample"))
        d = dir(fullfile(cfg.repoRoot,"data_sample","*.standard.jsonl"));
        hasStandardJsonl = ~isempty(d);
    end
    tf = hasWorksCsv || hasWorksJsonl || hasStandardJsonl;
catch
    tf = false;
end
end