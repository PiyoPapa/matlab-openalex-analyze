function cfg = setup(varargin)
%TOPICMAP.SETUP  Resolve hub roots, add paths, create run directory, return cfg.
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
    autoHub  = string(fileparts(repoRoot)); % .../github

    envHub = string(getenv("OPENALEX_MATLAB_HUB"));
    if strlength(hubArg) > 0
        hubRoot = hubArg;
    elseif strlength(envHub) > 0
        hubRoot = envHub;
    else
        hubRoot = autoHub;
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
    cfg.runsRoot = fullfile(repoRoot,"runs");

    cfg.runId  = datestr(now,"yyyymmdd_HHMMSS");
    cfg.runDir = fullfile(cfg.runsRoot,cfg.runId);
    if ~isfolder(cfg.runDir), mkdir(cfg.runDir); end

    cfg.seed = 1;
    cfg.env  = struct(); % env.checkで埋める
end
