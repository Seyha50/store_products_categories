<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ProductController extends Controller
{
    // 1. index: បង្ហាញទាំងអស់
    public function index()
    {
        return response()->json(
            Product::with('category')->where('isDeleted', 0)
                ->orderByDesc('ProductID')->get()
        );
    }

    // 2. store: បញ្ចូលថ្មី
    public function store(Request $request)
    {
        $data = $request->validate([
            'ProductName'  => 'required|string|max:100',
            'Description'  => 'nullable|string|max:255',
            'CategoryID'   => 'required|exists:categories,category_id',
            'Barcode'      => 'nullable|string|max:255|unique:products,Barcode',
            'Expiredate'   => 'nullable|date',
            'Qty'          => 'required|integer|min:0',
            'UnitPriceIn'  => 'required|numeric|min:0',
            'UnitPriceOut' => 'required|numeric|min:0',
            'ProductImage' => 'nullable|image|max:2048',
        ]);

        if ($request->hasFile('ProductImage')) {
            $data['ProductImage'] = $request->file('ProductImage')->store('products', 'public');
        }

        $product = Product::create($data);
        return response()->json($product->load('category'), 201);
    }

    // 3. show: បង្ហាញម្នាក់
    public function show(Product $product)
    {
        abort_if($product->isDeleted, 404, 'Product not found');
        return response()->json($product->load('category'));
    }

    // 4. update: កែប្រែ
    public function update(Request $request, Product $product)
    {
        $data = $request->validate([
            'ProductName'  => 'required|string|max:100',
            'Description'  => 'nullable|string|max:255',
            'CategoryID'   => 'required|exists:categories,category_id',
            'Barcode'      => ['nullable','string','max:255',
                               Rule::unique('products','Barcode')->ignore($product->ProductID,'ProductID')],
            'Expiredate'   => 'nullable|date',
            'Qty'          => 'required|integer|min:0',
            'UnitPriceIn'  => 'required|numeric|min:0',
            'UnitPriceOut' => 'required|numeric|min:0',
            'ProductImage' => 'nullable|image|max:2048',
        ]);

        if ($request->hasFile('ProductImage')) {
            if ($product->ProductImage) Storage::disk('public')->delete($product->ProductImage);
            $data['ProductImage'] = $request->file('ProductImage')->store('products', 'public');
        }

        $product->update($data);
        return response()->json($product->load('category'));
    }

    // 5. destroy: លុប (soft delete ដោយប្រើ isDeleted)
    public function destroy(Product $product)
    {
        $product->update(['isDeleted' => 1]);
        return response()->json(['message' => 'Product deleted']);
    }
}
