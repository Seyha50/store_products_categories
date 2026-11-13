<?php

use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ProductController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::apiResource('categories', CategoryController::class);
Route::apiResource('products', ProductController::class);

Route::get('images/{path}', function (string $path) {
    abort_unless(Storage::disk('public')->exists($path), 404);
    return Storage::disk('public')->response($path);
})->where('path', '.*');
