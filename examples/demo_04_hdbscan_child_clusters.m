%% demo_04_hdbscan_child_clusters : Step 0-2 (Parent HDBSCAN)
% - Reuse demo03 embeddings (DO NOT recompute embeddings here)
% - PCA space for clustering, UMAP only for visualization coordinates
% - Parent clustering with HDBSCAN (File Exchange dependency)

clear; clc;

cfg = topicmap.setup();
cfg = topicmap.env_check(cfg); %[output:457e8e65]

rng(cfg.seed);

%% Step 0: Locate and load demo03 embeddings (E, meta)
% Policy: demo04 MUST NOT regenerate embeddings.
% It loads demo03_embeddings.mat from an existing run directory.

demo03RunDir = "";
if isfield(cfg,"input") && isfield(cfg.input,"demo03RunDir") && strlength(string(cfg.input.demo03RunDir))>0
    demo03RunDir = string(cfg.input.demo03RunDir);
end

if strlength(demo03RunDir)==0
    % Auto-discover the newest run that contains demo03_embeddings.mat
    runsRoot = fullfile(cfg.repoRoot, "runs");
    assert(isfolder(runsRoot), "runs/ folder not found: %s", runsRoot);

    d = dir(fullfile(runsRoot, "**", "demo03_embeddings.mat"));
    assert(~isempty(d), "No demo03_embeddings.mat found under runs/. Run demo03 first.");

    [~, idxNewest] = max([d.datenum]);
    demo03RunDir = string(d(idxNewest).folder);
end

embMat = fullfile(demo03RunDir, "demo03_embeddings.mat");
assert(isfile(embMat), "Missing demo03 embeddings: %s", embMat);

S = load(embMat, "E", "meta");
assert(isfield(S,"E") && isfield(S,"meta"), "demo03_embeddings.mat must contain E and meta.");

E = S.E;
meta = S.meta;

fprintf("demo04 input (demo03 run): %s\n", demo03RunDir); %[output:5c8b31ff]
fprintf("Loaded embeddings: %d x %d\n", size(E,1), size(E,2)); %[output:5abc76f6]

% Basic alignment sanity
N = size(E,1);
assert(isfield(meta,"work_id") && numel(meta.work_id)==N, "meta.work_id must align with E rows.");
assert(isfield(meta,"year")    && numel(meta.year)==N,    "meta.year must align with E rows.");
assert(isfield(meta,"title")   && numel(meta.title)==N,   "meta.title must align with E rows.");

%% Step 1: Feature space for clustering (PCA) and 2D coords (reuse or compute)
pcaDims = 50;
if isfield(cfg,"demo04") && isstruct(cfg.demo04) && isfield(cfg.demo04,"pcaDims") && ~isempty(cfg.demo04.pcaDims)
    pcaDims = cfg.demo04.pcaDims;
end

fprintf("Computing PCA(%d) for clustering space...\n", pcaDims); %[output:36cb366f]
[~, Zpca] = pca(double(E), "NumComponents", pcaDims);

% 2D coordinates for plotting:
% Prefer to reuse demo03_umap2d.csv (to keep comparability across demos)
U2 = [];
embedMethod = "";

u2Csv = fullfile(demo03RunDir, "demo03_umap2d.csv");
if isfile(u2Csv) %[output:group:6f217633]
    T = readtable(u2Csv);
    % expects columns x,y aligned with meta.work_id
    if all(ismember(["work_id","x","y"], string(T.Properties.VariableNames)))
        % Join by work_id to ensure alignment
        key = string(meta.work_id(:));
        [tf, loc] = ismember(key, string(T.work_id));
        if all(tf)
            U2 = [T.x(loc), T.y(loc)];
            embedMethod = "UMAP(reuse demo03_umap2d.csv)";
            fprintf("Reused U2 from demo03_umap2d.csv\n"); %[output:584d42ad]
        end
    end
end %[output:group:6f217633]

% If reuse failed, compute UMAP now (visualization only)
if isempty(U2)
    fprintf("demo03 U2 not reusable. Computing UMAP(2) for visualization...\n");

    % R2025b+ Swing issue: run_umap must be verbose 'none' or 'text'
    umapVerbose = "none";
    if isfield(cfg,"demo04") && isfield(cfg.demo04,"umapVerbose") && strlength(string(cfg.demo04.umapVerbose))>0
        umapVerbose = string(cfg.demo04.umapVerbose);
    end

    if exist("umap","file") ~= 0
        % Try built-in umap first (if available)
        try
            U2 = umap(Zpca, "Metric", "cosine", "NumDimensions", 2, "RandomState", cfg.seed);
            embedMethod = "UMAP(umap)";
        catch
            U2 = [];
        end
    end

    if isempty(U2) && exist("run_umap","file") ~= 0
        try
            [U2, ~, ~, ~] = run_umap(Zpca, ...
                "n_components", 2, ...
                "metric", "cosine", ...
                "n_neighbors", 15, ...
                "min_dist", 0.1, ...
                "random_state", cfg.seed, ...
                "verbose", umapVerbose);
            embedMethod = "UMAP(run_umap)";
        catch
            U2 = [];
        end
    end

    if isempty(U2)
        error("UMAP not available. Reuse demo03_umap2d.csv or install umap/run_umap.");
    end
end

fprintf("U2 ready: %s | size=%d x %d\n", embedMethod, size(U2,1), size(U2,2)); %[output:274ab1d6]

%% Step 2: Parent clustering with HDBSCAN (File Exchange dependency)
% HDBSCAN should run on PCA space (Zpca), NOT UMAP.
% We attempt common function names used by File Exchange implementations.
minClusterSize = 20;
minSamples = [];  % leave empty unless your implementation needs it

if isfield(cfg,"demo04") && isstruct(cfg.demo04)
    if isfield(cfg.demo04,"minClusterSize") && ~isempty(cfg.demo04.minClusterSize)
        minClusterSize = cfg.demo04.minClusterSize;
    end
    if isfield(cfg.demo04,"minSamples") && ~isempty(cfg.demo04.minSamples)
        minSamples = cfg.demo04.minSamples;
    end
end

fprintf("Running parent HDBSCAN (min_cluster_size=%d) on PCA space...\n", minClusterSize); %[output:76ee2878]

parent_label = [];
parent_prob = [];

% ---- Ensure HDBSCAN is on path (vendored File Exchange code) ----
local_ensure_hdbscan_on_path(cfg);

% ---- Try function variants (adjust this once you decide which FE package you ship) ----
if exist("hdbscan","file") ~= 0
    % Variant A: hdbscan(X, minPts) or hdbscan(X, minPts, Name,Value...)
    try
        if isempty(minSamples)
            out = hdbscan(Zpca, minClusterSize);
        else
            out = hdbscan(Zpca, minClusterSize, "MinSamples", minSamples);
        end

        % Normalize possible outputs
        if isstruct(out)
            if isfield(out,"labels"), parent_label = out.labels; end
            if isfield(out,"probabilities"), parent_prob = out.probabilities; end
        elseif istable(out)
            if ismember("labels", out.Properties.VariableNames), parent_label = out.labels; end
            if ismember("probabilities", out.Properties.VariableNames), parent_prob = out.probabilities; end
        elseif isnumeric(out)
            parent_label = out;
        end
    catch
        parent_label = [];
    end
end

if isempty(parent_label) && exist("HDBSCAN","file") ~= 0 %[output:group:9eb221d8]
    % Variant B: class-based API
    try
        % Jorsorokin-HDBSCAN (File Exchange) API:
        %   clusterer = HDBSCAN(X);
        %   clusterer.minpts = ...;
        %   clusterer.minclustsize = ...;
        %   clusterer.run_hdbscan();
        %   labels = clusterer.labels;  % noise = 0
        %   prob   = clusterer.P;       % membership probability
        clusterer = HDBSCAN(Zpca);
        if ~isempty(minSamples)
            clusterer.minpts = double(minSamples);
        else
            % keep package default unless you want to tie it to minClusterSize:
            % clusterer.minpts = max(2, floor(minClusterSize/2));
        end
        clusterer.minclustsize = double(minClusterSize);
        clusterer.run_hdbscan(); %[output:2db075df]

        if isprop(clusterer,"labels")
            parent_label = clusterer.labels;
        end
        if isprop(clusterer,"P")
            parent_prob = clusterer.P;
        end
    catch
        parent_label = [];
    end
end %[output:group:9eb221d8]

if isempty(parent_label)
    w1 = string(which("hdbscan","-all"));
    w2 = string(which("HDBSCAN","-all"));
    msg = strjoin([ ...
        "HDBSCAN implementation not found / not callable.", newline, ...
        "Expected entry points: hdbscan(...) or HDBSCAN class.", newline, ...
        newline, ...
        "Diagnostic:", newline, ...
        "  which hdbscan -all:", newline, ...
        "    " + strjoin(w1, newline + "    "), newline, ...
        "  which HDBSCAN -all:", newline, ...
        "    " + strjoin(w2, newline + "    "), newline, ...
        newline, ...
        "Fix:", newline, ...
        "  Vendor a File Exchange HDBSCAN package into the repo (e.g. third_party/hdbscan/) and rerun.", newline ...
    ], "");
    error("%s", msg);
end

parent_label = parent_label(:);
if isempty(parent_prob)
    parent_prob = nan(N,1);
else
    parent_prob = parent_prob(:);
end

assert(numel(parent_label)==N, "parent_label length must match N.");
assert(numel(parent_prob)==N,  "parent_prob length must match N.");

% Noise label differs by implementation:
% - many implementations use -1 for noise
% - Jorsorokin-HDBSCAN uses 0 for noise
noiseMask = (parent_label <= 0);
nNoise = sum(noiseMask);
nClust = numel(unique(parent_label(~noiseMask)));

fprintf("Parent HDBSCAN done. clusters=%d | noise=%d (%.1f%%)\n", ... %[output:group:818fde2d] %[output:39fb4f73]
    nClust, nNoise, 100*nNoise/N); %[output:group:818fde2d] %[output:39fb4f73]

%% Step 2b: Quick stability check (min_cluster_size sensitivity)
% Goal: reduce "it worked by accident" feeling by reporting sensitivity.
% We do NOT claim an "optimal" setting. We only show how results change.

doStability = true;
if isfield(cfg,"demo04") && isstruct(cfg.demo04) && isfield(cfg.demo04,"doStability") && ~isempty(cfg.demo04.doStability)
    doStability = logical(cfg.demo04.doStability);
end

if doStability %[output:group:794d44f7]
    fprintf("Running quick stability check (min_cluster_size sweep)...\n"); %[output:600ff19c]

    sweepFactors = [0.8 1.0 1.2];
    if isfield(cfg,"demo04") && isstruct(cfg.demo04) && isfield(cfg.demo04,"sweepFactors") ...
            && ~isempty(cfg.demo04.sweepFactors)
        sweepFactors = double(cfg.demo04.sweepFactors);
    end

    mcsGrid = unique(max(2, round(minClusterSize .* sweepFactors(:)')));
    mcsGrid = mcsGrid(:);

    % pair sampling for co-clustering stability (avoid heavy O(N^2))
    pairM = 20000;
    if isfield(cfg,"demo04") && isstruct(cfg.demo04) && isfield(cfg.demo04,"stabilityPairs") ...
            && ~isempty(cfg.demo04.stabilityPairs)
        pairM = double(cfg.demo04.stabilityPairs);
    end
    pairM = min(pairM, N*(N-1)/2);

    rng(cfg.seed);
    i1 = randi(N, pairM, 1);
    i2 = randi(N, pairM, 1);
    sameIdx = (i1 == i2);
    i2(sameIdx) = mod(i2(sameIdx), N) + 1; % force i1 != i2

    labelsAll = cell(numel(mcsGrid),1);
    nClustersAll = zeros(numel(mcsGrid),1);
    noisePctAll  = zeros(numel(mcsGrid),1);

    for s = 1:numel(mcsGrid)
        mcs = mcsGrid(s);
        [lab, prob] = local_call_hdbscan(Zpca, mcs, minSamples, N); %[output:5c057a45] %[output:78f947ce] %[output:6f426460]
        labelsAll{s} = lab;

        % Noise label differs by implementation:
        % - many implementations use -1 for noise
        % - Jorsorokin-HDBSCAN uses 0 for noise
        noiseMaskS = (lab <= 0);
        nNoiseS = sum(noiseMaskS);
        nClustS = numel(unique(lab(~noiseMaskS)));
        nClustersAll(s) = nClustS;
        noisePctAll(s)  = 100 * nNoiseS / N;

        fprintf("  mcs=%d -> clusters=%d | noise=%.1f%%\n", mcs, nClustS, noisePctAll(s)); %[output:46e8ef4a] %[output:53a9f83e] %[output:8188684c]
    end

    % co-clustering agreement between the baseline (closest to 1.0 factor) and others
    % Definition: for sampled pairs, compare "same cluster (excluding noise)" decisions.
    % This is NOT a perfect metric, but it is cheap and interpretable.
    basePos = find(mcsGrid == minClusterSize, 1);
    if isempty(basePos), basePos = round(numel(mcsGrid)/2); end
    labBase = labelsAll{basePos};

    agree = nan(numel(mcsGrid),1);
    for s = 1:numel(mcsGrid)
        labS = labelsAll{s};

        % exclude pairs where either point is noise in either run
        ok = (labBase(i1) > 0) & (labBase(i2) > 0) & (labS(i1) > 0) & (labS(i2) > 0);
        if ~any(ok)
            agree(s) = NaN;
            continue;
        end

        sameBase = (labBase(i1(ok)) == labBase(i2(ok)));
        sameS    = (labS(i1(ok))    == labS(i2(ok)));
        agree(s) = mean(sameBase == sameS);
    end

    T_stab = table(mcsGrid, nClustersAll, noisePctAll, agree, ...
        'VariableNames', {'min_cluster_size','n_clusters','noise_pct','pairwise_agreement_vs_base'});

    outStabCsv = fullfile(cfg.runDir, "demo04_parent_stability.csv");
    writetable(T_stab, outStabCsv);
    fprintf("Wrote: %s\n", outStabCsv); %[output:4d65613e]
end %[output:group:794d44f7]

%% Save parent clustering results (for Step3+ and reproducibility)
% Use legacy 'VariableNames' syntax and column normalization (R2025b-safe)
work_id_all = string(meta.work_id(:));
year_all    = double(meta.year(:));
x_all       = U2(:,1); x_all = x_all(:);
y_all       = U2(:,2); y_all = y_all(:);

T_parent = table(work_id_all, year_all, parent_label, parent_prob, x_all, y_all, ...
    'VariableNames', {'work_id','year','parent_cluster','parent_probability','x','y'});

outParentCsv = fullfile(cfg.runDir, "demo04_parent_clusters.csv");
writetable(T_parent, outParentCsv);
fprintf("Wrote: %s\n", outParentCsv); %[output:7de27f78]

outParentMat = fullfile(cfg.runDir, "demo04_parent_state.mat");
save(outParentMat, "demo03RunDir", "embMat", "pcaDims", "Zpca", "U2", "embedMethod", ...
    "minClusterSize", "minSamples", "parent_label", "parent_prob", "-v7.3");
fprintf("Wrote: %s\n", outParentMat); %[output:97d40db3]

fprintf("demo04 Step0-2 complete. Next: Step3 reps, Step4 child HDBSCAN.\n"); %[output:6cec2da5]

%% Local helper: attempt to add vendored HDBSCAN implementation to path
function local_ensure_hdbscan_on_path(cfg)
   if exist("hdbscan","file") ~= 0 || exist("HDBSCAN","file") ~= 0
       return;
   end
    % Pinpoint addpath policy (NO genpath):
    % Put the File Exchange package under:
    %   <repoRoot>/third_party/hdbscan/
    % and ensure HDBSCAN.m exists somewhere inside it.
    vendorRoot = fullfile(cfg.repoRoot, "third_party", "hdbscan");
    if ~isfolder(vendorRoot)
        return;
    end

    d = dir(fullfile(vendorRoot, "**", "HDBSCAN.m"));
    if ~isempty(d)
        hdbscanDir = string(d(1).folder);
        addpath(hdbscanDir);   % add folder containing HDBSCAN.m

        % Add a few common dependency subfolders (without genpath)
        sub = ["source","src","utils","lib","code"];
        for k = 1:numel(sub)
            p = fullfile(hdbscanDir, sub(k));
            if isfolder(p)
                addpath(p);
            end
        end

        rehash toolboxcache;
        fprintf("Added vendored HDBSCAN path(s):\n");
        fprintf("  %s\n", hdbscanDir);
        for k = 1:numel(sub)
            p = fullfile(hdbscanDir, sub(k));
            if isfolder(p), fprintf("  %s\n", string(p)); end
        end
        fprintf("  which HDBSCAN: %s\n", string(which("HDBSCAN")));
    end
end

%% Local helper: Call File Exchange HDBSCAN implementation robustly
function [parent_label, parent_prob] = local_call_hdbscan(Zpca, minClusterSize, minSamples, N)
    parent_label = [];
    parent_prob  = [];

    if exist("hdbscan","file") ~= 0
        try
            if isempty(minSamples)
                out = hdbscan(Zpca, minClusterSize);
            else
                out = hdbscan(Zpca, minClusterSize, "MinSamples", minSamples);
            end

            if isstruct(out)
                if isfield(out,"labels"), parent_label = out.labels; end
                if isfield(out,"probabilities"), parent_prob = out.probabilities; end
            elseif istable(out)
                if ismember("labels", out.Properties.VariableNames), parent_label = out.labels; end
                if ismember("probabilities", out.Properties.VariableNames), parent_prob = out.probabilities; end
            elseif isnumeric(out)
                parent_label = out;
            end
        catch
            parent_label = [];
        end
    end

    if isempty(parent_label) && exist("HDBSCAN","file") ~= 0
        try
            clusterer = HDBSCAN(Zpca);
            if ~isempty(minSamples)
                clusterer.minpts = double(minSamples);
            end
            clusterer.minclustsize = double(minClusterSize);
            clusterer.run_hdbscan();
            if isprop(clusterer,"labels"), parent_label = clusterer.labels; end
            if isprop(clusterer,"P"),     parent_prob  = clusterer.P;      end
        catch
            parent_label = [];
        end
    end

    if isempty(parent_label)
        error("HDBSCAN implementation not found/callable. Expected hdbscan(...) or HDBSCAN class.");
    end

    parent_label = parent_label(:);
    if isempty(parent_prob)
        parent_prob = nan(N,1);
    else
        parent_prob = parent_prob(:);
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:457e8e65]
%   data: {"dataType":"text","outputData":{"text":"[topicmap.env_check] OK: required checks passed.\n  demo_02 ready: 1\n  demo_03 ready: 1\n  demo_01 sample-ready (legacy optionalOk): 0\n","truncated":false}}
%---
%[output:5c8b31ff]
%   data: {"dataType":"text","outputData":{"text":"demo04 input (demo03 run): D:\\workspace\\github\\openalex-topic-map\\runs\\20251223_101837\n","truncated":false}}
%---
%[output:5abc76f6]
%   data: {"dataType":"text","outputData":{"text":"Loaded embeddings: 1000 x 384\n","truncated":false}}
%---
%[output:36cb366f]
%   data: {"dataType":"text","outputData":{"text":"Computing PCA(50) for clustering space...\n","truncated":false}}
%---
%[output:584d42ad]
%   data: {"dataType":"text","outputData":{"text":"Reused U2 from demo03_umap2d.csv\n","truncated":false}}
%---
%[output:274ab1d6]
%   data: {"dataType":"text","outputData":{"text":"U2 ready: UMAP(reuse demo03_umap2d.csv) | size=1000 x 2\n","truncated":false}}
%---
%[output:76ee2878]
%   data: {"dataType":"text","outputData":{"text":"Running parent HDBSCAN (min_cluster_size=20) on PCA space...\n","truncated":false}}
%---
%[output:2db075df]
%   data: {"dataType":"text","outputData":{"text":"Training cluster hierarchy...\n\tData matrix size:\n\t\t1000 points x 50 dimensions\n\n\tMin # neighbors: 5\n\tMin cluster size: 20\n\tMin # of clusters: 1\n\tSkipping every 0 iteration\n\nTraining took 0.185 seconds\n","truncated":false}}
%---
%[output:39fb4f73]
%   data: {"dataType":"text","outputData":{"text":"Parent HDBSCAN done. clusters=1 | noise=369 (36.9%)\n","truncated":false}}
%---
%[output:600ff19c]
%   data: {"dataType":"text","outputData":{"text":"Running quick stability check (min_cluster_size sweep)...\n","truncated":false}}
%---
%[output:5c057a45]
%   data: {"dataType":"text","outputData":{"text":"Training cluster hierarchy...\n\tData matrix size:\n\t\t1000 points x 50 dimensions\n\n\tMin # neighbors: 5\n\tMin cluster size: 16\n\tMin # of clusters: 1\n\tSkipping every 0 iteration\n\nTraining took 0.137 seconds\n","truncated":false}}
%---
%[output:46e8ef4a]
%   data: {"dataType":"text","outputData":{"text":"  mcs=16 -> clusters=1 | noise=36.9%n","truncated":false}}
%---
%[output:78f947ce]
%   data: {"dataType":"text","outputData":{"text":"Training cluster hierarchy...\n\tData matrix size:\n\t\t1000 points x 50 dimensions\n\n\tMin # neighbors: 5\n\tMin cluster size: 20\n\tMin # of clusters: 1\n\tSkipping every 0 iteration\n\nTraining took 0.068 seconds\n","truncated":false}}
%---
%[output:53a9f83e]
%   data: {"dataType":"text","outputData":{"text":"  mcs=20 -> clusters=1 | noise=36.9%n","truncated":false}}
%---
%[output:6f426460]
%   data: {"dataType":"text","outputData":{"text":"Training cluster hierarchy...\n\tData matrix size:\n\t\t1000 points x 50 dimensions\n\n\tMin # neighbors: 5\n\tMin cluster size: 24\n\tMin # of clusters: 1\n\tSkipping every 0 iteration\n\nTraining took 0.072 seconds\n","truncated":false}}
%---
%[output:8188684c]
%   data: {"dataType":"text","outputData":{"text":"  mcs=24 -> clusters=1 | noise=36.9%n","truncated":false}}
%---
%[output:4d65613e]
%   data: {"dataType":"text","outputData":{"text":"Wrote: D:\\workspace\\github\\openalex-topic-map\\runs\\20251223_145931\\demo04_parent_stability.csv\n","truncated":false}}
%---
%[output:7de27f78]
%   data: {"dataType":"text","outputData":{"text":"Wrote: D:\\workspace\\github\\openalex-topic-map\\runs\\20251223_145931\\demo04_parent_clusters.csv\n","truncated":false}}
%---
%[output:97d40db3]
%   data: {"dataType":"text","outputData":{"text":"Wrote: D:\\workspace\\github\\openalex-topic-map\\runs\\20251223_145931\\demo04_parent_state.mat\n","truncated":false}}
%---
%[output:6cec2da5]
%   data: {"dataType":"text","outputData":{"text":"demo04 Step0-2 complete. Next: Step3 reps, Step4 child HDBSCAN.\n","truncated":false}}
%---
