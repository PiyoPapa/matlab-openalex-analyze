function cfg = setup(varargin)
%TOPICMAP.SETUP  Resolve hub roots and paths. (NO run directory creation)
    p = inputParser;
    addParameter(p,"HubRoot","",@(x)ischar(x)||isstring(x));
    parse(p,varargin{:});
    hubArg = string(p.Results.HubRoot);

    % mfilename("fullpath") points to .../matlab-openalex-analyze/src/+topicmap/setup.m
    % We want repoRoot = .../matlab-openalex-analyze
    thisFile = mfilename("fullpath");
    pkgDir   = fileparts(thisFile);      % .../src/+topicmap
    srcDir   = fileparts(pkgDir);        % .../src
    repoRoot = fileparts(srcDir);        % .../matlab-openalex-analyze
    envHub = string(getenv("OPENALEX_MATLAB_HUB"));
    if strlength(hubArg) > 0
        hubRoot = hubArg;
    elseif strlength(envHub) > 0
        hubRoot = envHub;
    else
        % Safe default: treat this repository as the hub root.
        % Users may override via OPENALEX_MATLAB_HUB or the HubRoot parameter.
        hubRoot = repoRoot;
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
    % Ch_02 will start from pipeline JSONL (not normalize CSV).
    cfg.input = struct();
    cfg.input.pipelineJsonl = "";  % user sets this (or Ch_02 sets)

    % Text policy for embeddings
    cfg.text = struct();
    cfg.text.policy = "title+abstract";   % fixed decision (A)
    cfg.text.maxChars = 6000;             % safety cap per document

    % ---------------------------
    % Sample defaults (Ch_01)
    % ---------------------------
    cfg.sample = struct();
    % Prefer standard JSONL sample (pipeline output format)
    cfg.sample.worksJsonl = "";      % recommended for Ch_01
    cfg.sample.worksCsv   = "";      % optional for Ch_01
    cfg.sample.embeddingMat = "";    % optional for Ch_01

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
