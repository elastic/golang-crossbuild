module.exports = {
  "dataSource": "prs",
  "prefix": "",
  "onlyMilestones": false,
  "ignoreLabels": ["closed", "automation", "enhancement", "fix",
    "internal", "feature", "feat", "docs", "chore", "refactor", "ci",
    "test", "Team:Automation"],
  "groupBy": {
      "Enhancements": ["enhancement", "internal", "feature", "feat"],
      "Bug Fixes": ["bug", "fix"],
      "Documentation": ["docs", "question"],
      "No user affected": ["chore", "refactor", "perf", "test", "style", "automation"],
      "CI": ["ci"]
  },
  "template": {
      commit: ({ message, url, author, name }) => `- [${message}](${url}) - ${author ? `@${author}` : name}`,
      issue: "- {{name}} [{{text}}]({{url}})",
      label: "[**{{label}}**]",
      noLabel: "closed",
      changelogTitle: "",
      release: "## Go {{release}}\n\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-arm` - linux/arm64\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-armel` - linux/armv5, linux/armv6\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-armhf` - linux/armv7\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-base`\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-darwin` - darwin/amd64 (MacOS 10.11, MacOS 10.14)\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-main` - linux/i386, linux/amd64, windows/386, windows/amd64\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-main-debian7` - linux/i386, linux/amd64, windows/386, windows/amd64\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-main-debian8` - linux/i386, linux/amd64, windows/386, windows/amd64\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-main-debian9` - linux/i386, linux/amd64, windows/386, windows/amd64\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-main-debian10` - linux/i386, linux/amd64, windows/386, windows/amd64\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-main-debian11` - linux/i386, linux/amd64, windows/386, windows/amd64\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-mips` - linux/mips64, linux/mips64el\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-mips32` - linux/mips, linux/mipsle\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-ppc` - linux/ppc64, linux/ppc64le\n- `docker.elastic.co/beats-dev/golang-crossbuild:{{release}}-s390x` - linux/s390x\n{{body}}",
      group: function (placeholders) {
        var icon = "🙈"
        if(placeholders.heading == 'Enhancements'){
          icon = "🚀"
        } else if(placeholders.heading == 'Bug Fixes'){
          icon = "🐛"
        } else if(placeholders.heading == 'Documentation'){
          icon = "📚"
        } else if(placeholders.heading == 'No user affected'){
          icon = "🙈"
        } else if(placeholders.heading == 'CI'){
          icon = "⚙️"
        }
        return '\n#### ' + icon + ' ' + placeholders.heading + '\n';
      }
  }
}
