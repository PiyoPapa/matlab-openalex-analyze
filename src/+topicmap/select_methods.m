function plan = select_methods(cfg, opts)
%TOPICMAP.SELECT_METHODS Choose methods based on available dependencies.
%
% plan = topicmap.select_methods(cfg)
% plan = topicmap.select_methods(cfg, "PreferUMAP", true, "PreferHDBSCAN", true)
%
% Required policy (fixed):
%   - Stats and Machine Learning Toolbox required
% Optional:
%   - UMAP / HDBSCAN / BERT / GPU
%
% Output plan fields (strings):
%   plan.reducer   : "umap" | "pca"
%   plan.clusterer : "hdbscan" | "kmeans"
%   plan.embedder  : "bert" | "precomputed" | "none"
%
% Also returns booleans in plan.flags.*

    arguments
        cfg (1,1) struct
        opts.PreferUMAP     (1,1) logical = true
        opts.PreferHDBSCAN (1,1) logical = true
    end

    preferUMAP    = opts.PreferUMAP;
    preferHDBSCAN = opts.PreferHDBSCAN;

    if ~isfield(cfg, "env") || ~isstruct(cfg.env)
        error("topicmap:select_methods:NoEnv", "cfg.env is missing. Run cfg = topicmap.env_check(cfg) first.");
    end

    % Reducer
    if preferUMAP && isfield(cfg.env,"hasUMAP") && cfg.env.hasUMAP
        reducer = "umap";
    else
        reducer = "pca";
    end

    % Clusterer
    if preferHDBSCAN && isfield(cfg.env,"hasHDBSCAN") && cfg.env.hasHDBSCAN
        clusterer = "hdbscan";
    else
        clusterer = "kmeans";
    end

    % Embedder (demo_01 uses precomputed by default)
    embedder = "none";
    hasPrecomputed = isfield(cfg,"sample") && isstruct(cfg.sample) && isfield(cfg.sample,"embeddingMat") ...
        && strlength(string(cfg.sample.embeddingMat))>0 && isfile(cfg.sample.embeddingMat);

    if hasPrecomputed
        embedder = "precomputed";
    elseif isfield(cfg.env,"hasBERT") && cfg.env.hasBERT
        embedder = "bert";
    end

    plan = struct();
    plan.reducer   = reducer;
    plan.clusterer = clusterer;
    plan.embedder  = embedder;

    plan.flags = struct();
    plan.flags.preferUMAP    = preferUMAP;
    plan.flags.preferHDBSCAN = preferHDBSCAN;
    plan.flags.hasPrecomputed = hasPrecomputed;
    plan.flags.hasGPU = isfield(cfg.env,"hasGPU") && cfg.env.hasGPU;
end
