<script lang="ts">
	interface Props {
		allItems: string[];
		checkedItems: Set<string>;
		onFilterChange: (visibleSet: Set<string>, mode: 'all' | 'todo' | 'completed') => void;
	}

	let { allItems, checkedItems, onFilterChange }: Props = $props();

	const allCount = $derived(allItems.length);
	const todoCount = $derived(allItems.filter((item) => !checkedItems.has(item)).length);
	const completedCount = $derived(allItems.filter((item) => checkedItems.has(item)).length);

	const todoPercent = $derived(allCount > 0 ? Math.round((todoCount / allCount) * 100) : 0);
	const completedPercent = $derived(
		allCount > 0 ? Math.round((completedCount / allCount) * 100) : 0
	);

	function showAll() {
		onFilterChange(new Set(allItems), 'all');
	}

	function showTodo() {
		onFilterChange(new Set(allItems.filter((item) => !checkedItems.has(item))), 'todo');
	}

	function showCompleted() {
		onFilterChange(new Set(allItems.filter((item) => checkedItems.has(item))), 'completed');
	}
</script>

<div class="filter-buttons">
	<button onclick={showAll}>All ({allCount})</button>
	<button onclick={showTodo}>Todo ({todoCount} - {todoPercent}%)</button>
	<button onclick={showCompleted}>Completed ({completedCount} - {completedPercent}%)</button>
</div>

<style>
	.filter-buttons {
		display: flex;
		gap: 0.5rem;
		margin-bottom: 1rem;
	}
</style>
