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
    W = repmat(struct(), n, 1);
    for i = 1:n
        try
            W(i) = jsondecode(lines(i));
        catch ME
            error("topicmap:jsonl:Parse", "Failed to parse JSONL at line %d: %s", i, ME.message);
        end
    end
end
