<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CategoryController extends Controller
{
    public function index() { return response()->json(Category::orderBy('category_name')->get()); }

    public function store(Request $request)
    {
        $data = $request->validate([
            'category_name' => 'required|string|max:50',
            'description'   => 'nullable|string|max:255',
            'image'         => 'required|image|max:2048',
        ]);
        $data['image'] = $request->file('image')->store('categories', 'public');
        return response()->json(Category::create($data), 201);
    }

    public function show(Category $category) { return response()->json($category); }

    public function update(Request $request, Category $category)
    {
        $data = $request->validate([
            'category_name' => 'required|string|max:50',
            'description'   => 'nullable|string|max:255',
            'image'         => 'nullable|image|max:2048',
        ]);
        if ($request->hasFile('image')) {
            Storage::disk('public')->delete($category->image);
            $data['image'] = $request->file('image')->store('categories', 'public');
        }
        $category->update($data);
        return response()->json($category);
    }

    public function destroy(Category $category)
    {
        DB::transaction(function () use ($category) {
            // Product deletion is normally a soft delete (isDeleted = 1), but
            // category deletion must remove the child rows first because the
            // foreign key does not allow deleting a referenced category.
            $products = $category->products()->get(['ProductID', 'ProductImage']);
            foreach ($products as $product) {
                if ($product->ProductImage) {
                    Storage::disk('public')->delete($product->ProductImage);
                }
                $product->delete();
            }

            Storage::disk('public')->delete($category->image);
            $category->delete();
        });

        return response()->json(['message' => 'Category deleted']);
    }
}
