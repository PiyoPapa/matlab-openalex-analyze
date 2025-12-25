function runDir = make_run_dir(cfg, tag, varargin)
%TOPICMAP.MAKE_RUN_DIR Create a timestamped run folder under cfg.baseOutDir.
%
%   runDir = topicmap.make_run_dir(cfg, "Ch03")
%   runDir = topicmap.make_run_dir(cfg, "Ch03", 'timestamp', datetime(...))
%
% Folder name: <YYYYMMDD_HHMMSS>_<tag>

    p = inputParser;
    p.addRequired('cfg', @(x) isstruct(x));
    p.addRequired('tag', @(x) (isstring(x)||ischar(x)) && strlength(string(x))>0);
    p.addParameter('timestamp', datetime('now','TimeZone','local'), @(x) isdatetime(x) && isscalar(x));
    p.parse(cfg, tag, varargin{:});

    tag = normalize_tag_(string(p.Results.tag));
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

function tagOut = normalize_tag_(tagIn)
%NORMALIZE_TAG_ Normalize run tags to stable, user-facing chapter IDs.
%
% Accepts legacy tags (e.g., "demo02", "demo_02") and normalizes them to "Ch02".
% This prevents externally visible run folders from carrying outdated naming.

    s = string(tagIn);
    s = strtrim(s);
    s = lower(s);
    s = regexprep(s, "\s+", "");     % remove spaces
    s = replace(s, "_", "");         % remove underscores
    s = replace(s, "-", "");         % remove hyphens

    % Common legacy prefixes → chapter
    % demo02, demo_02, chapter02, ch02, etc.
    m = regexp(s, "^(demo|chapter|ch)(\d{1,2})$", "tokens", "once");
    if ~isempty(m)
        n = str2double(m{2});
        if ~isnan(n)
            tagOut = "Ch" + compose("%02d", n);
            return;
        end
    end

    % If already looks like ChNN after stripping, keep as ChNN
    m = regexp(s, "^ch(\d{1,2})$", "tokens", "once");
    if ~isempty(m)
        n = str2double(m{1});
        if ~isnan(n)
            tagOut = "Ch" + compose("%02d", n);
            return;
        end
    end

    % Otherwise: keep caller-provided tag, but stabilize casing.
    % (Avoid making unexpected breaking changes for custom tags.)
    tagOut = string(tagIn);
end