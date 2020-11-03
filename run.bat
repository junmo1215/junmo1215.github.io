IF NOT "" == %1 goto run_with_host
goto run_without_host

:run_with_host
bundle exec jekyll serve -w --host=%1
goto end

:run_without_host
bundle exec jekyll serve
goto end

:end
