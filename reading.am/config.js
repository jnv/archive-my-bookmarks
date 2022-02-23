export default {
  // outputDir: join(__dirname, '..', 'bookmarks', 'reading.am'),
  outputDir: new URL('../bookmarks/reading.am', import.meta.url).pathname,
}
