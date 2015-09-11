function buildSolution($solution) {
    msbuild `
      /t:Clean `
      /t:Build `
      /p:Configuration=release `
      /v:n `
      /nologo `
      /p:VisualStudioVersion=12.0 `
      $solution
}