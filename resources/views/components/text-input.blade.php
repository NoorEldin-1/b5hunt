@props(['disabled' => false])

<input @disabled($disabled) {{ $attributes->merge(['class' => 'input input-bordered bg-base-100 text-base-content w-full']) }}>
