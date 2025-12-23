function runDir = make_run_dir(cfg, tag, varargin)
%TOPICMAP.MAKE_RUN_DIR Create a timestamped run folder under cfg.baseOutDir.
%
%   runDir = topicmap.make_run_dir(cfg, "demo03")
%   runDir = topicmap.make_run_dir(cfg, "demo03", 'timestamp', datetime(...))
%
% Folder name: <YYYYMMDD_HHMMSS>_<tag>

    p = inputParser;
    p.addRequired('cfg', @(x) isstruct(x));
    p.addRequired('tag', @(x) (isstring(x)||ischar(x)) && strlength(string(x))>0);
    p.addParameter('timestamp', datetime('now','TimeZone','local'), @(x) isdatetime(x) && isscalar(x));
    p.parse(cfg, tag, varargin{:});

    tag = string(p.Results.tag);
    ts  = p.Results.timestamp;

    assert(isfield(cfg, "baseOutDir") && strlength(string(cfg.baseOutDir))>0, ...
        "cfg.baseOutDir is missing. Call topicmap.setup() first.");

    tsStr = string(datestr(ts, "yyyymmdd_HHMMSS"));
    runId = tsStr + "_" + tag;

    runDir = fullfile(string(cfg.baseOutDir), runId);
    if ~isfolder(runDir)
        mkdir(runDir);
    end
end