function W = read_pipeline_jsonl(jsonlPath)
%TOPICMAP.READ_PIPELINE_JSONL Read OpenAlex works JSONL (pipeline output).
%
% W = topicmap.read_pipeline_jsonl(jsonlPath)
% - Returns a struct array W where each element corresponds to one JSON line.

    jsonlPath = string(jsonlPath);
    assert(strlength(jsonlPath)>0 && isfile(jsonlPath), "JSONL not found: %s", jsonlPath);

    txt = fileread(jsonlPath);
    lines = regexp(txt, '\r\n|\n|\r', 'split');
    lines = string(lines);
    lines = lines(strlength(strtrim(lines))>0);

    n = numel(lines);
    % Do NOT preallocate struct(): jsondecode output fields may vary by line.
    S = cell(n,1);
    allFields = string.empty(0,1);

    for i = 1:n
        try
            si = jsondecode(char(lines(i)));
            if ~isstruct(si)
                error("Decoded JSON is not a struct.");
            end
            S{i} = si;
            allFields = union(allFields, string(fieldnames(si)));
        catch ME
            error("topicmap:jsonl:Parse", "Failed to parse JSONL at line %d: %s", i, ME.message);
        end
    end

    % Normalize fields across all records to avoid "dissimilar structures" assignment errors.
    for i = 1:n
        si = S{i};
        f = string(fieldnames(si));
        missing = setdiff(allFields, f);
        for k = 1:numel(missing)
            si.(missing(k)) = []; %#ok<AGROW>
        end
        S{i} = si;
    end

    W = vertcat(S{:});
end
