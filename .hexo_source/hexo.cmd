@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "%~dp0\node_modules\hexo\bin\hexo" %*
) ELSE (
  node  "%~dp0\node_modules\hexo\bin\hexo" %*
)