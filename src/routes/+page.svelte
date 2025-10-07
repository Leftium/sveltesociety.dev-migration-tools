<script lang="ts">
	import githubJson from '$lib/data/github.json';
</script>

{#each Object.keys(githubJson) as githubUrl, index}
	{@const ownerRepo = githubUrl.replace('https://github.com/', '')}
	<div>
		{index + 1} <a href={githubUrl} target="_blank">{ownerRepo}</a>
	</div>
{/each}
