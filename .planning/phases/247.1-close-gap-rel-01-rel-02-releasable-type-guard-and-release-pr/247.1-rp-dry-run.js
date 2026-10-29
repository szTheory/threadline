const {GitHub, Manifest} = require('release-please');
(async () => {
  const github = await GitHub.create({owner: 'szTheory', repo: 'threadline', token: process.env.RP_TOKEN});
  const m = await Manifest.fromManifest(github, 'main', 'release-please-config.json', '.release-please-manifest.json');
  const ex = JSON.parse(process.env.EXCL || '[]');
  if (ex.length) m.repositoryConfig['.'].excludePaths = ex;
  const prs = await m.buildPullRequests();
  console.log('EXCLUDE', JSON.stringify(ex));
  console.log('CANDIDATES', prs.length, prs.map(p => p.title.toString()));
})().catch(e => { console.error(e); process.exit(1); });
