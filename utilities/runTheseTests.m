function runTheseTests()
% RUNTHESETESTS Run all tests in the project.

%   Copyright 2018-2020 The MathWorks, Inc.

project = matlab.project.currentProject;
runtests(project.RootFolder);

end
