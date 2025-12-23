function cfg = setup(varargin)
%TOPICMAP.SETUP  Resolve hub roots and paths. (NO run directory creation)
    p = inputParser;
    addParameter(p,"HubRoot","",@(x)ischar(x)||isstring(x));
    parse(p,varargin{:});
    hubArg = string(p.Results.HubRoot);

    % mfilename("fullpath") points to .../openalex-topic-map/src/+topicmap/setup.m
    % We want repoRoot = .../openalex-topic-map
    thisFile = mfilename("fullpath");
    pkgDir   = fileparts(thisFile);      % .../src/+topicmap
    srcDir   = fileparts(pkgDir);        % .../src
    repoRoot = fileparts(srcDir);        % .../openalex-topic-map
    autoHub  = string(fileparts(repoRoot)); % fallback only

    envHub = string(getenv("OPENALEX_MATLAB_HUB"));
    if strlength(hubArg) > 0
        hubRoot = hubArg;
    elseif strlength(envHub) > 0
        hubRoot = envHub;
    else
        error("topicmap:HubRootRequired", ...
            "OPENALEX_MATLAB_HUB is required. autoHub fallback is disabled by default.");
    end

    pipelineRoot  = fullfile(hubRoot,"matlab-openalex-pipeline");
    normalizeRoot = fullfile(hubRoot,"matlab-openalex-normalize");

    cfg.repoRoot = repoRoot;
    cfg.hubRoot  = hubRoot;
    cfg.pipelineRoot  = pipelineRoot;
    cfg.normalizeRoot = normalizeRoot;

    cfg.srcRoot = fullfile(repoRoot,"src");
    cfg.examplesRoot = fullfile(repoRoot,"examples");
    cfg.dataSampleRoot = fullfile(repoRoot,"data_sample");
    % Ensure topicmap src is on path (no genpath)
    addpath(cfg.srcRoot);

    % unified output base (no side effects)
    cfg.baseOutDir = fullfile(hubRoot,"data_processed","openalex-topicmap");
    cfg.runDir = "";   % demos must create explicitly

    cfg.seed = 1;
    cfg.env  = struct(); % env.checkで埋める

    % ---------------------------
    % Inputs / text policy (topic map)
    % ---------------------------
    % demo_02 will start from pipeline JSONL (not normalize CSV).
    cfg.input = struct();
    cfg.input.pipelineJsonl = "";  % user sets this (or demo_02 sets)

    % Text policy for embeddings
    cfg.text = struct();
    cfg.text.policy = "title+abstract";   % fixed decision (A)
    cfg.text.maxChars = 6000;             % safety cap per document

    % ---------------------------
    % Sample defaults (demo_01)
    % ---------------------------
    cfg.sample = struct();
    % Prefer standard JSONL sample (pipeline output format)
    cfg.sample.worksJsonl = "";      % recommended for demo_01
    cfg.sample.worksCsv   = "";      % optional for demo_01
    cfg.sample.embeddingMat = "";    % optional for demo_01

    % Auto-detect a sample JSONL under repoRoot/data_sample (if present)
    sampleDir = fullfile(repoRoot, "data_sample");
    if isfolder(sampleDir)
        cand = fullfile(sampleDir, "openalex_MATLAB_cursor_en_1000.standard.jsonl");
        if isfile(cand)
            cfg.sample.worksJsonl = cand;
        else
            d = dir(fullfile(sampleDir, "*.standard.jsonl"));
            if ~isempty(d)
                cfg.sample.worksJsonl = fullfile(d(1).folder, d(1).name);
            end
        end
    end
end
