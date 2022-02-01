classdef testgensubimage < matlab.unittest.TestCase
    %TESGENSUBIMAGE
    %   
    %  Copyright 2022. David Atkinson. University College London
 
% Examples of set up and imports
    methods(TestClassSetup)
        function prepareData(testCase)

            load mri D  % in-built brain MR (128 x 128)
            img = double(D(:,:,1,12)) ;

            % Set shot sequence
            N = size(img,1) ;  % number of phase encodes
            nshot = 8 ;
            npershot = N / nshot ;

            shot2ky = cell(nshot,1) ;

            for ishot = 1:nshot
                shot2ky{ishot} = ishot : npershot : N ;
            end

            testCase.shot2ky = shot2ky ;
            testCase.testimg = img ;
        end
    end

    properties
        shot2ky
        testimg
    end

% import matlab.unittest.constraints.IsEqualTo
% import matlab.unittest.constraints.AbsoluteTolerance
% import matlab.unittest.constraints.RelativeTolerance

    methods(Test)
        function testShotCorrect(testCase)
            % this is essentially also a test of d_apply_shot as
            % shotCorrect is just a wrapper plus FFT.
            % Overall, code needs a bit of refactoring to simplify.

            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.AbsoluteTolerance
            import matlab.unittest.constraints.RelativeTolerance

            % applying zero should not change data
            ksp = i2k(testCase.testimg) ;

            shot = 4;
            tapply = 0 ;

            im0  = shotCorrect(ksp, shot, testCase.shot2ky, tapply)  ;

            testCase.verifyThat(im0, IsEqualTo(testCase.testimg, ...
                'Within', AbsoluteTolerance(max(testCase.testimg(:))/10000)) )

            % out and back should be original

            tapply2 = 4 ;

            imout = shotCorrect(ksp, shot, testCase.shot2ky, tapply2)  ;
            imback = shotCorrect(i2k(imout), shot, testCase.shot2ky, -tapply2)  ;

            testCase.verifyThat(abs(imback), IsEqualTo(testCase.testimg, ...
                'Within', AbsoluteTolerance(max(testCase.testimg(:))/100000)) )
        end

        function testGensubimage(testCase)
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.AbsoluteTolerance
            import matlab.unittest.constraints.RelativeTolerance

            % [X, Y, kbad] = gensubimage(imgin, shot, shot2ky, trans, n, refShot)

            % Not straightforward to test usefully. Currently just basic
            % checks on outputs.

            shot = 6 ; refShot = 6 ; n = 1;  trans = 3 ; 
            imgOrder = 1; cshifts = [0 0] ;
            [X, Y, kbad] = gensubimage(testCase.testimg, shot, testCase.shot2ky, trans, n, refShot, imgOrder, cshifts) ;

            testCase.verifyThat(size(X,4),IsEqualTo(n))
            testCase.verifyThat(size(kbad,3),IsEqualTo(n))
            testCase.verifyThat(Y(1,1),IsEqualTo(trans))

            % no motion and shot==refShot so difference should be zero
            shot = 6 ; refShot = 6 ; n = 1;  trans = 0 ; 
            [X, Y, kbad] = gensubimage(testCase.testimg, shot, testCase.shot2ky, trans, n, refShot, imgOrder, cshifts) ;

            testCase.verifyThat(X(:,:,1,1),IsEqualTo(0*testCase.testimg,'Within',...
                AbsoluteTolerance(max(testCase.testimg(:))/100000)))


        end


    end % methods

end % classdef

